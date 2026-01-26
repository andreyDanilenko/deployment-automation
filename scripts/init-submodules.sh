#!/bin/bash

# Скрипт для инициализации Git Submodules
# Использование: ./scripts/init-submodules.sh

set -e

echo "🚀 Инициализация Git Submodules..."

# Перейти в директорию скрипта
cd "$(dirname "$0")/.."

# Проверить, что мы в Git репозитории
if [ ! -d ".git" ]; then
    echo "❌ Ошибка: Это не Git репозиторий"
    exit 1
fi

# Инициализировать submodules
echo "📦 Инициализация submodules..."
git submodule update --init --recursive

# Проверить статус
echo ""
echo "✅ Submodules инициализированы!"
echo ""
echo "📊 Статус submodules:"
git submodule status

echo ""
echo "💡 Для обновления submodules используйте:"
echo "   git submodule update --remote"


