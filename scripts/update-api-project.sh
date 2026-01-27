#!/bin/bash

# Скрипт для обновления api-project-marketplace репозитория
# Используется при деплое для синхронизации с upstream

set -e

# Определяем директорию скрипта и deployment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOYMENT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$DEPLOYMENT_DIR")"

cd "$PROJECT_ROOT" || exit 1

SSH_KEY_PATH="$HOME/.ssh/github_keys"
BRANCH="master"
UPSTREAM_URL="git@github.com:andreyDanilenko/admin-panel-golang.git"

# Определяем путь к репозиторию (может быть api-project-marketplace или api-admin-marketplace)
REPO_PATH=""
if [ -d "./api-project-marketplace" ]; then
    REPO_PATH="./api-project-marketplace"
    REPO_NAME="api-project-marketplace"
elif [ -d "./api-admin-marketplace" ]; then
    REPO_PATH="./api-admin-marketplace"
    REPO_NAME="api-admin-marketplace"
else
    echo "Ошибка: репозиторий не найден"
    echo "Искали: ./api-project-marketplace и ./api-admin-marketplace"
    echo "Текущая директория: $(pwd)"
    exit 1
fi

# Настройка SSH для работы с GitHub
eval "$(ssh-agent -s)"
ssh-add "$SSH_KEY_PATH" || true

echo "Используем репозиторий: $REPO_NAME в $REPO_PATH"

echo "Обновляем $REPO_NAME..."
cd "$REPO_PATH" || exit 1

# Добавляем upstream если его нет
if ! git remote | grep -q upstream; then
    git remote add upstream "$UPSTREAM_URL" || true
fi

# Получаем все изменения
git fetch --all

# Переключаемся на нужную ветку и синхронизируем
git checkout "$BRANCH" || git checkout -b "$BRANCH"
git reset --hard "upstream/$BRANCH" || git reset --hard "origin/$BRANCH"

cd - > /dev/null || exit 1

echo "Репозиторий $REPO_NAME успешно обновлён!"
