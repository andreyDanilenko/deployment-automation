#!/bin/bash

# Скрипт для обновления всех репозиториев
# Используется при деплое для синхронизации с upstream
#
# Структура на сервере:
# - /root/project/api-project-marketplace/ - монорепа admin-panel-golang
# - /root/project/backend/ - backend репозиторий
# - /root/project/frontend/ - frontend репозиторий
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

# Репозитории для обновления
# TODO: Замените на ваши реальные репозитории и ветки
declare -A REPOS=(
    ["api-project-marketplace"]="master:git@github.com:andreyDanilenko/admin-panel-golang.git"
    ["backend"]="main:git@github.com:YOUR_USERNAME/backend.git"
    ["frontend"]="main:git@github.com:YOUR_USERNAME/frontend.git"
)

# Обновляем каждый репозиторий
for repo_name in "${!REPOS[@]}"; do
    repo_info="${REPOS[$repo_name]}"
    IFS=':' read -r branch upstream_url <<< "$repo_info"
    repo_path="./$repo_name"
    
    if [ ! -d "$repo_path" ]; then
        echo "Репозиторий $repo_name не найден в $repo_path, пропускаем..."
        continue
    fi
    
    echo "Обновляем $repo_name..."
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
done

echo "Все репозитории успешно обновлены!"
