#!/bin/bash

# Основной скрипт деплоя
# Обновляет api-project-marketplace и перезапускает контейнеры

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOYMENT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$DEPLOYMENT_DIR" || exit 1

echo "Начинаем деплой..."

# Обновляем api-project-marketplace
echo "Обновляем api-project-marketplace..."
bash "$SCRIPT_DIR/update-api-project.sh"

# Перезапускаем контейнеры
echo "Перезапускаем контейнеры..."
docker-compose down
docker-compose up -d --build

echo "Деплой завершён успешно!"
