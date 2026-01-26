# Quick Start Guide

Быстрый старт для работы с репозиторием-конфигом.

## Текущая структура (frontend + backend в соседних папках)

Если у вас структура:
```
myProject/
├── frontend/
├── backend/
└── deployment/
```

### Запуск

```bash
cd deployment
docker-compose up -d
```

Готово! Сервисы доступны на `http://localhost`

## Работа с Git Submodules

### Добавить новый проект

```bash
cd deployment
git submodule add <URL-проекта> projects/project-name
git submodule update --init --recursive
```

### Обновить docker-compose.yml

```yaml
services:
  project-name-frontend:
    build:
      context: ./projects/project-name/frontend
      dockerfile: Dockerfile
```

### Создать Nginx конфигурацию

```bash
cp nginx/conf.d/template.conf.example nginx/conf.d/project-name.conf
# Отредактируйте project-name.conf
```

### Запустить

```bash
docker-compose up -d --build
```

## Полезные команды

```bash
# Инициализация submodules
./scripts/init-submodules.sh

# Обновление всех проектов
git submodule update --remote

# Просмотр статуса
docker-compose ps

# Логи
docker-compose logs -f

# Остановка
docker-compose down
```

## Документация

- [README.md](./README.md) - Полная документация
- [SETUP.md](./SETUP.md) - Пошаговая настройка
- [ARCHITECTURE.md](./ARCHITECTURE.md) - Архитектура системы


