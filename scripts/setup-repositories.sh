#!/bin/bash

# Скрипт для первоначальной настройки репозиториев
# Используется при первом деплое на сервер
# 
# Структура на сервере:
# - /root/project/api-project-marketplace/ - уже существует (монорепа admin-panel-golang)
# - /root/project/backend/ - клонируется
# - /root/project/frontend/ - клонируется
# - /root/project/deployment/ - этот репозиторий

set -e

# Определяем директорию скрипта и deployment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOYMENT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$DEPLOYMENT_DIR")"

cd "$PROJECT_ROOT" || exit 1

SSH_KEY_PATH="$HOME/.ssh/github_keys"

# Настройка SSH для работы с GitHub
eval "$(ssh-agent -s)"
ssh-add "$SSH_KEY_PATH" || true
ssh -T git@github.com || true

# Репозитории для клонирования
# TODO: Замените на ваши реальные репозитории
declare -A REPOS=(
    ["backend"]="git@github.com:YOUR_USERNAME/backend.git:main"
    ["frontend"]="git@github.com:YOUR_USERNAME/frontend.git:main"
)

# Клонируем репозитории
for repo_name in "${!REPOS[@]}"; do
    repo_info="${REPOS[$repo_name]}"
    IFS=':' read -r repo_url branch <<< "$repo_info"
    repo_path="./$repo_name"
    
    if [ -d "$repo_path" ]; then
        echo "Репозиторий $repo_name уже существует в $repo_path, пропускаем..."
    else
        echo "Клонируем $repo_name в $repo_path..."
        git clone -b "$branch" "$repo_url" "$repo_path" || {
            echo "Ошибка при клонировании $repo_name"
            exit 1
        }
    fi
done

# Проверяем наличие api-project-marketplace
if [ ! -d "./api-project-marketplace" ]; then
    echo "ВНИМАНИЕ: api-project-marketplace не найден в $PROJECT_ROOT"
    echo "Убедитесь, что монорепа admin-panel-golang развернута в ./api-project-marketplace"
fi

echo "Все репозитории успешно настроены!"
