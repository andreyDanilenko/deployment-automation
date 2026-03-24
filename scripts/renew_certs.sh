#!/bin/bash

# ==============================================
# ОСНОВНОЙ СКРИПТ ДЛЯ СЕРВЕРА С ОТПРАВКОЙ В TELEGRAM
# ==============================================

# Пути
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

# Домены
DOMAINS=(
    "lifedream.tech"
    "habits.lifedream.tech"
    "n8n.lifedream.tech"
)

# Email для Let's Encrypt
EMAIL="danilenko.a.g@mail.ru"

# Функция логирования
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Загружаем переменные из .env
if [ -f "$PROJECT_DIR/.env" ]; then
    export $(grep -v '^#' "$PROJECT_DIR/.env" | xargs)
    log "✅ Переменные окружения загружены"
fi

# Функция отправки в Telegram
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

# Функция проверки существования сертификата для домена
cert_exists() {
    local domain="$1"
    [ -f "$SSL_DIR/config/live/$domain/fullchain.pem" ] && \
    [ -f "$SSL_DIR/config/live/$domain/privkey.pem" ]
}

# Функция получения сертификата для домена
get_certificate() {
    local domain="$1"
    log "Создаем сертификат для $domain"
    certbot certonly --standalone \
        -d "$domain" \
        --config-dir "$SSL_DIR/config" \
        --work-dir "$SSL_DIR/work" \
        --logs-dir "$SSL_DIR/logs" \
        --agree-tos \
        --email "$EMAIL" \
        --non-interactive
    
    if [ $? -eq 0 ]; then
        log "✅ Сертификат для $domain создан"
        return 0
    else
        log "❌ Ошибка при создании сертификата для $domain"
        return 1
    fi
}

# Начало
log "=== ЗАПУСК ОБНОВЛЕНИЯ СЕРТИФИКАТОВ ==="

# 1. Останавливаем контейнеры
log "Останавливаем Docker контейнеры..."
cd "$PROJECT_DIR" || exit 1
"${DOCKER_COMPOSE[@]}" down

if [ $? -ne 0 ]; then
    log "❌ Ошибка при остановке контейнеров"
    exit 1
fi

log "✅ Контейнеры остановлены"

# 2. Проверяем каждый домен и получаем/обновляем сертификаты
NEEDS_RENEW=false
for DOMAIN in "${DOMAINS[@]}"; do
    if cert_exists "$DOMAIN"; then
        log "🔍 Сертификат для $DOMAIN найден"
        NEEDS_RENEW=true
    else
        log "⚠️ Сертификат для $DOMAIN НЕ НАЙДЕН"
        get_certificate "$DOMAIN"
    fi
done

# 3. Если все сертификаты существуют, выполняем обновление
if [ "$NEEDS_RENEW" = true ]; then
    log "🔄 Выполняем обновление существующих сертификатов..."
    certbot renew --standalone \
        --config-dir "$SSL_DIR/config" \
        --work-dir "$SSL_DIR/work" \
        --logs-dir "$SSL_DIR/logs" \
        --non-interactive
    
    if [ $? -eq 0 ]; then
        log "✅ Certbot обновление выполнено"
    else
        log "⚠️ Certbot завершился с ошибкой"
    fi
fi

# 4. Копируем сертификаты в папку Nginx
log "Копируем сертификаты в $SSL_DIR..."
for DOMAIN in "${DOMAINS[@]}"; do
    if [ -f "$SSL_DIR/config/live/$DOMAIN/fullchain.pem" ]; then
        cp "$SSL_DIR/config/live/$DOMAIN/fullchain.pem" "$SSL_DIR/$DOMAIN.crt"
        cp "$SSL_DIR/config/live/$DOMAIN/privkey.pem" "$SSL_DIR/$DOMAIN.key"
        log "✅ $DOMAIN: сертификаты скопированы"
    else
        log "❌ $DOMAIN: сертификаты не найдены в Certbot"
    fi
done

# 5. Запускаем контейнеры
log "Запускаем Docker контейнеры..."
"${DOCKER_COMPOSE[@]}" up -d
if [ $? -eq 0 ]; then
    log "✅ Контейнеры запущены"
else
    log "❌ Ошибка при запуске контейнеров"
    exit 1
fi

# ==============================================
# ОТПРАВКА ОТЧЕТА В TELEGRAM
# ==============================================

log "Формируем отчет о сертификатах..."

# Формируем отчет
REPORT="📊 <b>Еженедельный отчет о SSL-сертификатах</b>\n"
REPORT+="📅 $(date '+%d.%m.%Y %H:%M')\n"
REPORT+="🖥 Сервер: $(hostname)\n"
REPORT+="─────────────────────\n\n"

for DOMAIN in "${DOMAINS[@]}"; do
    if [ -f "$SSL_DIR/$DOMAIN.crt" ]; then
        # Получаем дату истечения
        EXPIRY=$(openssl x509 -in "$SSL_DIR/$DOMAIN.crt" -noout -enddate | cut -d= -f2)
        
        # Считаем сколько дней осталось
        EXPIRY_SEC=$(date -d "$EXPIRY" +%s)
        NOW_SEC=$(date +%s)
        DAYS_LEFT=$(( ($EXPIRY_SEC - $NOW_SEC) / 86400 ))
        
        # Выбираем эмодзи в зависимости от срока
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

# Добавляем информацию о последнем обновлении
REPORT+="─────────────────────\n"
REPORT+="🔄 Последнее обновление: $(date '+%d.%m.%Y %H:%M')\n"
REPORT+="✅ Скрипт выполнен успешно"

# Отправляем отчет
send_telegram "$REPORT"

log "=== ОБНОВЛЕНИЕ ЗАВЕРШЕНО ==="
