#!/bin/bash
# Deploy script — использует docker compose v2 (без ошибки ContainerConfig)
# Запуск: ./deploy.sh или bash deploy.sh

set -e
cd "$(dirname "$0")"

if ! docker compose version &>/dev/null; then
  echo "❌ docker compose (v2) не найден. Установите: apt install docker-compose-plugin"
  exit 1
fi

echo "=== Pulling latest images ==="
docker compose pull habits_api habits_frontend nest_satellite article_app article_frontend

echo "=== Recreating containers ==="
docker compose down
docker compose up -d --build

echo "=== Status ==="
docker compose ps

echo "=== Done ==="
