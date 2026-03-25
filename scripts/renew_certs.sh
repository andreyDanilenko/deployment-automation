#!/bin/bash

# ==============================================
# Let's Encrypt (certbot --standalone) + Telegram
# Перед выпуском: docker compose down, порт 80 свободен для certbot.
#
# Если n8n.lifedream.tech в DNS указывает на Beget/другой хост (страница
# «домен не прилинкован»), LE не дойдёт до этого сервера. Пока не поправите
# A-запись n8n → IP этого VPS, запускайте с:
#   RENEW_CERT_SKIP_N8N=1 /path/to/renew_certs.sh
# ==============================================

PROJECT_DIR="${CERT_RENEW_PROJECT_DIR:-/root/project/deployment}"
SSL_DIR="$PROJECT_DIR/nginx/ssl"
LOG_FILE="/var/log/cert_renewal.log"

if docker compose version &>/dev/null 2>&1; then
    DOCKER_COMPOSE=(docker compose)
elif command -v docker-compose &>/dev/null; then
    DOCKER_COMPOSE=(docker-compose)
else
    echo "Не найден ни 'docker compose', ни 'docker-compose'" >&2
    exit 1
fi

DOMAINS=(
    "lifedream.tech"
    "habits.lifedream.tech"
    "n8n.lifedream.tech"
)

if [ "${RENEW_CERT_SKIP_N8N:-0}" = "1" ]; then
    DOMAINS=("lifedream.tech" "habits.lifedream.tech")
fi

EMAIL="danilenko.a.g@mail.ru"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

if [ -f "$PROJECT_DIR/.env" ]; then
    export $(grep -v '^#' "$PROJECT_DIR/.env" | xargs)
    log "✅ Переменные окружения загружены"
fi

send_telegram() {
    local message="$1"
    if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]; then
        curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d chat_id="${TELEGRAM_CHAT_ID}" \
            -d text="$message" \
            -d parse_mode="HTML" > /dev/null
        log "✅ Отчет отправлен в Telegram"
    else
        log "⚠️ Telegram не настроен (нет токена или chat_id)"
    fi
}

cert_exists() {
    local domain="$1"
    [ -f "$SSL_DIR/config/live/$domain/fullchain.pem" ] && \
    [ -f "$SSL_DIR/config/live/$domain/privkey.pem" ]
}

get_certificate() {
    local domain="$1"
    log "Выпускаем сертификат (certonly --standalone) для $domain"
    if certbot certonly --standalone \
        -d "$domain" \
        --config-dir "$SSL_DIR/config" \
        --work-dir "$SSL_DIR/work" \
        --logs-dir "$SSL_DIR/logs" \
        --agree-tos \
        --email "$EMAIL" \
        --non-interactive; then
        log "✅ Сертификат для $domain создан"
        return 0
    fi
    log "❌ Ошибка при создании сертификата для $domain"
    return 1
}

log "=== ЗАПУСК ОБНОВЛЕНИЯ СЕРТИФИКАТОВ (standalone) ==="

cd "$PROJECT_DIR" || exit 1

log "Останавливаем Docker контейнеры..."
if ! "${DOCKER_COMPOSE[@]}" down; then
    log "❌ Ошибка при остановке контейнеров"
    exit 1
fi
log "✅ Контейнеры остановлены"

HAS_LIVE_CERT=false
ISSUE_FAILED=false
for DOMAIN in "${DOMAINS[@]}"; do
    if cert_exists "$DOMAIN"; then
        log "🔍 Certbot live для $DOMAIN найден"
        HAS_LIVE_CERT=true
    else
        log "⚠️ Certbot live для $DOMAIN нет — выпускаем новый"
        if ! get_certificate "$DOMAIN"; then
            ISSUE_FAILED=true
        fi
    fi
done

if [ "$HAS_LIVE_CERT" = true ]; then
    log "🔄 Certbot renew (продление)..."
    if certbot renew --standalone \
        --config-dir "$SSL_DIR/config" \
        --work-dir "$SSL_DIR/work" \
        --logs-dir "$SSL_DIR/logs" \
        --non-interactive; then
        log "✅ certbot renew завершён"
    else
        log "⚠️ certbot renew завершился с ошибкой"
    fi
fi

log "Копируем сертификаты в $SSL_DIR (*.crt / *.key)..."
MISSING_AFTER_COPY=0
for DOMAIN in "${DOMAINS[@]}"; do
    if [ -f "$SSL_DIR/config/live/$DOMAIN/fullchain.pem" ]; then
        cp "$SSL_DIR/config/live/$DOMAIN/fullchain.pem" "$SSL_DIR/$DOMAIN.crt"
        cp "$SSL_DIR/config/live/$DOMAIN/privkey.pem" "$SSL_DIR/$DOMAIN.key"
        log "✅ $DOMAIN: скопировано для Nginx"
    else
        log "❌ $DOMAIN: нет fullchain.pem в Certbot"
        MISSING_AFTER_COPY=$((MISSING_AFTER_COPY + 1))
    fi
done

if [ "$MISSING_AFTER_COPY" -gt 0 ] || [ "$ISSUE_FAILED" = true ]; then
    log "❌ SSL неполный — compose up не выполняем. Для n8n: DNS A → IP VPS (не Beget). Временно: RENEW_CERT_SKIP_N8N=1"
    REPORT_FAIL="⚠️ <b>renew_certs.sh: ошибка SSL</b>\n🖥 $(hostname)\nСм. $LOG_FILE\nЕсли n8n на Beget — сначала A-запись на этот сервер или SKIP_N8N."
    send_telegram "$REPORT_FAIL"
    exit 1
fi

log "Запускаем Docker контейнеры..."
if ! "${DOCKER_COMPOSE[@]}" up -d; then
    log "❌ Ошибка при запуске контейнеров"
    exit 1
fi
log "✅ Контейнеры запущены"

log "Формируем отчет о сертификатах..."

REPORT="📊 <b>Еженедельный отчет о SSL-сертификатах</b>\n"
REPORT+="📅 $(date '+%d.%m.%Y %H:%M')\n"
REPORT+="🖥 Сервер: $(hostname)\n"
REPORT+="─────────────────────\n\n"

for DOMAIN in "${DOMAINS[@]}"; do
    if [ -f "$SSL_DIR/$DOMAIN.crt" ]; then
        EXPIRY=$(openssl x509 -in "$SSL_DIR/$DOMAIN.crt" -noout -enddate | cut -d= -f2)
        EXPIRY_SEC=$(date -d "$EXPIRY" +%s)
        NOW_SEC=$(date +%s)
        DAYS_LEFT=$(( ($EXPIRY_SEC - NOW_SEC) / 86400 ))

        if [ $DAYS_LEFT -lt 30 ]; then
            STATUS="🔴 <b>СКОРО ИСТЕКАЕТ!</b>"
        elif [ $DAYS_LEFT -lt 60 ]; then
            STATUS="🟡 Меньше 60 дней"
        else
            STATUS="🟢 Более 60 дней"
        fi

        REPORT+="🔑 <b>$DOMAIN</b>\n"
        REPORT+="   📅 Истекает: $EXPIRY\n"
        REPORT+="   ⏳ Осталось: $DAYS_LEFT дней\n"
        REPORT+="   $STATUS\n\n"
    else
        REPORT+="❌ <b>$DOMAIN</b>: сертификат не найден!\n\n"
    fi
done

REPORT+="─────────────────────\n"
REPORT+="🔄 Последнее обновление: $(date '+%d.%m.%Y %H:%M')\n"
REPORT+="✅ Standalone + compose up выполнены"

send_telegram "$REPORT"

log "=== ОБНОВЛЕНИЕ ЗАВЕРШЕНО ==="
