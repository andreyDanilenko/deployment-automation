#!/usr/bin/env bash
# Регистрирует Telegram Bot API webhook. Токен из deployment/.env (TELEGRAM_USER_BOT_TOKEN).
# Использование:
#   cd deployment && ./scripts/set-telegram-webhook.sh 'https://<tunnel>.trycloudflare.com/webhook/telegram-connect'
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ROOT}/.env"
URL="${1:-}"

if [[ -z "$URL" ]]; then
  echo "Usage: $0 'https://<host>/webhook/telegram-connect'" >&2
  exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
set -a
# shellcheck source=/dev/null
source "$ENV_FILE"
set +a

if [[ -z "${TELEGRAM_USER_BOT_TOKEN:-}" ]]; then
  echo "TELEGRAM_USER_BOT_TOKEN is empty in .env" >&2
  exit 1
fi

echo "Calling setWebhook (max 30s)..."
curl --max-time 30 -sS -X POST "https://api.telegram.org/bot${TELEGRAM_USER_BOT_TOKEN}/setWebhook" \
  -H "Content-Type: application/json" \
  -d "{\"url\":\"${URL}\"}"
echo ""
