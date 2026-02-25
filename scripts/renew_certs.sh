#!/bin/bash

# ==============================================
# ОСНОВНОЙ СКРИПТ ДЛЯ СЕРВЕРА
# ==============================================

# Пути
PROJECT_DIR="/root/project/deployment"
SSL_DIR="$PROJECT_DIR/nginx/ssl"
LOG_FILE="/var/log/cert_renewal.log"

# Домены
DOMAINS=(
    "lifedream.tech"
    "habits.lifedream.tech"
)

# Email для Let's Encrypt
EMAIL="danilenko.a.g@mail.ru"

# Функция логирования
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Начало
log "=== ЗАПУСК ОБНОВЛЕНИЯ СЕРТИФИКАТОВ ==="

# 1. Останавливаем контейнеры
log "Останавливаем Docker контейнеры..."
cd "$PROJECT_DIR" || exit 1
docker-compose down
if [ $? -eq 0 ]; then
    log "✅ Контейнеры остановлены"
else
    log "❌ Ошибка при остановке контen
    log "🆕 Сертификаты не найдены. СОЗДАЕМ новые..."
    
    for DOMAIN in "${DOMAINS[@]}"; do
        log "Создаем сертификат для $DOMAIN"
        certbot certonly --standalone \
            -d "$DOMAIN" \
            --config-dir "$SSL_DIR/config" \
            --work-dir "$SSL_DIR/work" \
            --logs
            --agree-tos \
            --email "$EMAIL"
        
        if [ $? -eq 0 ]; then
            log "✅ Сертификат для $DOMAIN создан"
        else
            log "❌ Ошибка при создании сертификата для $DOMAIN"
        fi
    done
else
    log "🔄 Сертификаты найдены. ОБНОВЛЯЕМ..."
    certbot renew --standalone \
        --config-dirDIR/logs" \
        --non-interactive
    
    if [ $? -eq 0 ]; then
        log "✅ Certbot обновление выполнено"
    else
        log "⚠️ Certbot завершился с ошибкой"
    fi
fi

# 3. Копируем сертификаты в папку Nginx
log "Копируем сертификаты в $SSL_DIR..."
for DOMAIN in "${DOMAINS[@]}"; do
    if [ -f "$SSL_DIR/config/live/$DOMAIN/fullchain.pem" ]; then
        cp "$SSL_DIR/config/live/$DOMAIN/fullchain.pem" "$SSL_DIR/$DOMAIN.crt"
        cp "$SSL_DIR/config/live/$DOMAIN/privkey.pem" "$SSL_DIR/$DOMAIN.key"
        log "✅ $DOMAIN: скопировано"
    else
        log "⚠️ $DOMAIN: сертифи� exit 1
docker-compose up -d
if [ $? -eq 0 ]; then
    log "✅ Контейнеры запущены"
else
    log "❌ Ошибка при запуске контейнеров"
    exit 1
fi

log "=== ОБНОВЛЕНИЕ ЗАВЕРШЕНО ==="
