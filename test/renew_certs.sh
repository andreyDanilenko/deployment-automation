#!/bin/bash

PROJECT_DIR="/Users/andrei/Documents/myProject/deployment/test"
SSL_DIR="$PROJECT_DIR/nginx/ssl"
DOMAINS=("lifedream.tech" "habits.lifedream.tech")

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "=== ТЕСТ НА MAC (ЛОКАЛЬНО) ==="

# Создаем тестовые самоподписанные сертификаты (для локального теста)
log "Создаю тестовые сертификаты локально..."

for DOMAIN in "${DOMAINS[@]}"; do
    # Создаем папки
    mkdir -p "$SSL_DIR/config/live/$DOMAIN"
    
    # Генерируем самоподписанные сертификаты (не через Certbot)
    openssl req -x509 -newkey rsa:2048 \
        -keyout "$SSL_DIR/config/live/$DOMAIN/privkey.pem" \
        -out "$SSL_DIR/config/live/$DOMAIN/fullchain.pem" \
        -days 365 -nodes -subj "/CN=$DOMAIN" 2>/dev/null
    
    # Копируем в nginx/ssl
    cp "$SSL_DIR/config/live/$DOMAIN/fullchain.pem" "$SSL_DIR/$DOMAIN.crt"
    cp "$SSL_DIR/config/live/$DOMAIN/privkey.pem" "$SSL_DIR/$DOMAIN.key"
    
    log "✅ $DOMAIN готов (тестовый)"
done

# Создаем тестовый docker-compose.yml
cat > "$PROJECT_DIR/docker-compose.yml" << 'EOF'
version: '3'
services:
  test:
    image: alpine:latest
    command: echo "Test container running"
EOF

# Запускаем тестовый контейнер
cd "$PROJECT_DIR" && docker-compose up -d

log "=== ТЕСТ ЗАВЕРШЕН ==="
ls -la "$SSL_DIR"
