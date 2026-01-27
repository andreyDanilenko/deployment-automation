#!/bin/bash

# Скрипт для обновления одного конкретного репозитория
# Используется когда нужно обновить только один проект
#
# Структура на сервере:
# - /root/project/api-project-marketplace/ - монорепа admin-panel-golang
# - /root/project/backend/ - backend репозиторий
# - /root/project/frontend/ - frontend репозиторий

set -e

if [ -z "$1" ]; then
    echo "Использование: $0 <repo-name>"
    echo "Доступные репозитории: api-project-marketplace, backend, frontend"
    exit 1
fi

# Определяем директорию скрипта и deployment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOYMENT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$DEPLOYMENT_DIR")"

cd "$PROJECT_ROOT" || exit 1

REPO_NAME="$1"
SSH_KEY_PATH="$HOME/.ssh/github_keys"

# Настройка SSH для работы с GitHub
eval "$(ssh-agent -s)"
ssh-add "$SSH_KEY_PATH" || true

# Маппинг репозиториев на их upstream и ветки
declare -A REPO_CONFIG=(
    ["api-project-marketplace"]="master:git@github.com:andreyDanilenko/admin-panel-golang.git"
    ["backend"]="main:git@github.com:YOUR_USERNAME/backend.git"
    ["frontend"]="main:git@github.com:YOUR_USERNAME/frontend.git"
)

if [ -z "${REPO_CONFIG[$REPO_NAME]}" ]; then
    echo "Ошибка: неизвестный репозиторий $REPO_NAME"
    echo "Доступные: api-project-marketplace, backend, frontend"
    exit 1
fi

repo_info="${REPO_CONFIG[$REPO_NAME]}"
IFS=':' read -r branch upstream_url <<< "$repo_info"
repo_path="./$REPO_NAME"

if [ ! -d "$repo_path" ]; then
    echo "Репозиторий $REPO_NAME не найден в $repo_path"
    exit 1
fi

echo "Обновляем $REPO_NAME..."
cd "$repo_path" || exit 1

# Добавляем upstream если его нет
if ! git remote | grep -q upstream; then
    git remote add upstream "$upstream_url" || true
fi

# Получаем все изменения
git fetch --all

# Переключаемся на нужную ветку и синхронизируем
git checkout "$branch" || git checkout -b "$branch"
git reset --hard "upstream/$branch" || git reset --hard "origin/$branch"

cd - > /dev/null || exit 1

echo "Репозиторий $REPO_NAME успешно обновлён!"
