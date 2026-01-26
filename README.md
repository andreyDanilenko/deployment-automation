# Deployment Configuration

Гибкая конфигурация для развертывания неограниченного количества проектов с использованием Docker Compose и Nginx.

## Архитектура

Этот репозиторий является **репозиторием-конфигом** (infrastructure/deploy репозиторий), который:

- Содержит общий `docker-compose.yml` для всех проектов
- Управляет конфигурацией Nginx для маршрутизации
- Ссылается на проекты через Git Submodules или прямые пути

**Принцип работы:**
- Каждый проект (репозиторий) содержит свои собственные `Dockerfile` в корне или подпапках
- Этот репозиторий содержит только инфраструктуру (docker-compose, nginx)
- Проекты подтягиваются через Git Submodules или копирование

## Структура

```
deployment/                    # Репозиторий-конфиг
├── docker-compose.yml         # Основной compose файл
├── nginx/
│   ├── nginx.conf             # Основная конфигурация Nginx
│   └── conf.d/                # Конфигурации для каждого проекта
│       ├── default.conf       # Конфигурация для текущего проекта
│       └── template.conf.example  # Шаблон для новых проектов
├── projects/                  # Проекты (через Git Submodules)
│   ├── project1/              # Git Submodule → репозиторий проекта 1
│   │   ├── frontend/
│   │   │   └── Dockerfile
│   │   └── backend/
│   │       └── Dockerfile
│   └── project2/              # Git Submodule → репозиторий проекта 2
│       └── ...
├── scripts/
│   └── init-submodules.sh     # Скрипт инициализации submodules
└── .gitmodules                # Конфигурация Git Submodules
```

## Начальная настройка

### Вариант 1: Git Submodules (Рекомендуется)

#### Шаг 1: Добавить проекты как Submodules

```bash
cd deployment

# Добавить проект 1
git submodule add <URL-репозитория-проекта-1> projects/project1

# Добавить проект 2
git submodule add <URL-репозитория-проекта-2> projects/project2

# Инициализировать и обновить submodules
git submodule update --init --recursive
```

#### Шаг 2: Настроить docker-compose.yml

Обновите `docker-compose.yml` для ссылки на проекты:

```yaml
services:
  project1-frontend:
    build:
      context: ./projects/project1/frontend
      dockerfile: Dockerfile
    container_name: project1-frontend
    networks:
      - app-network

  project1-backend:
    build:
      context: ./projects/project1/backend
      dockerfile: Dockerfile
    container_name: project1-backend
    networks:
      - app-network
```

#### Шаг 3: Обновить submodules

```bash
# Обновить все submodules до последних коммитов
git submodule update --remote

# Или обновить конкретный submodule
git submodule update --remote projects/project1
```

### Вариант 2: Прямое копирование (Проще для начала)

Если не хотите использовать Git Submodules, просто скопируйте папки проектов:

```bash
cd deployment
mkdir -p projects
cp -r ../frontend projects/project1-frontend
cp -r ../backend projects/project1-backend
```

Затем обновите `docker-compose.yml` соответственно.

## Быстрый старт

### 1. Инициализация (если используете Submodules)

```bash
# Клонировать репозиторий-конфиг с submodules
git clone --recursive <URL-репозитория-конфига>

# Или если уже клонировали без --recursive
git submodule update --init --recursive
```

### 2. Настройка переменных окружения

```bash
cp .env.example .env
# Отредактируйте .env файл при необходимости
```

### 3. Запуск всех сервисов

```bash
docker-compose up -d
```

### 4. Проверка статуса

```bash
docker-compose ps
```

## Добавление нового проекта

### Шаг 1: Добавить проект как Submodule

```bash
git submodule add <URL-нового-проекта> projects/new-project
git submodule update --init --recursive
```

### Шаг 2: Создать конфигурацию Nginx

```bash
cp nginx/conf.d/template.conf.example nginx/conf.d/new-project.conf
```

Отредактируйте `new-project.conf`:
- Измените `server_name` на домен нового проекта
- Обновите `proxy_pass` URLs на соответствующие сервисы

### Шаг 3: Добавить сервисы в docker-compose.yml

```yaml
services:
  new-project-frontend:
    build:
      context: ./projects/new-project/frontend
      dockerfile: Dockerfile
    container_name: new-project-frontend
    environment:
      - VITE_API_BASE_URL=http://new-project-backend:8080
    networks:
      - app-network

  new-project-backend:
    build:
      context: ./projects/new-project/backend
      dockerfile: Dockerfile
    container_name: new-project-backend
    environment:
      - SERVER_PORT=8080
    networks:
      - app-network
    depends_on:
      - postgres
```

### Шаг 4: Обновить зависимости Nginx

В `docker-compose.yml` обновите `depends_on` для nginx:

```yaml
nginx:
  depends_on:
    - project1-frontend
    - project1-backend
    - new-project-frontend
    - new-project-backend
```

### Шаг 5: Перезапустить сервисы

```bash
docker-compose up -d --build
docker-compose restart nginx
```

## Работа с Git Submodules

### Обновление проектов

```bash
# Обновить все submodules до последних коммитов
git submodule update --remote

# Обновить конкретный submodule
git submodule update --remote projects/project1

# Обновить до конкретного коммита
cd projects/project1
git checkout <commit-hash>
cd ../..
git add projects/project1
git commit -m "Update project1 to specific commit"
```

### Переключение версий проектов

```bash
# Перейти в директорию проекта
cd projects/project1

# Переключиться на нужную ветку/тег
git checkout main
# или
git checkout v1.0.0

# Вернуться в корень и закоммитить изменения
cd ../..
git add projects/project1
git commit -m "Update project1 to v1.0.0"
```

### Удаление Submodule

```bash
# Удалить submodule
git submodule deinit -f projects/project1
git rm -f projects/project1
rm -rf .git/modules/projects/project1
```

## Структура проектов

Каждый проект должен иметь следующую структуру:

```
project-name/
├── frontend/
│   ├── Dockerfile
│   ├── package.json
│   └── ...
├── backend/
│   ├── Dockerfile
│   ├── go.mod
│   └── ...
└── README.md
```

Или если проект монолитный:

```
project-name/
├── Dockerfile
├── package.json
└── ...
```

В `docker-compose.yml` укажите правильный путь:

```yaml
build:
  context: ./projects/project-name/frontend  # или ./projects/project-name
  dockerfile: Dockerfile
```

## Управление сервисами

### Остановка

```bash
docker-compose stop
```

### Остановка и удаление контейнеров

```bash
docker-compose down
```

### Пересборка конкретного проекта

```bash
docker-compose build project1-frontend
docker-compose up -d project1-frontend
```

### Просмотр логов

```bash
# Все сервисы
docker-compose logs -f

# Конкретный сервис
docker-compose logs -f project1-frontend
```

## SSL/HTTPS настройка

### 1. Получить SSL сертификаты

Используйте Let's Encrypt или другой провайдер.

### 2. Разместить сертификаты

```bash
mkdir -p nginx/ssl
# Скопируйте cert.pem и key.pem в nginx/ssl/
```

### 3. Раскомментировать SSL конфигурацию

В `nginx/conf.d/project-name.conf` раскомментируйте блок с SSL.

### 4. Перезапустить Nginx

```bash
docker-compose restart nginx
```

## Пример: Текущая структура (frontend + backend)

Для текущего проекта структура следующая:

```
deployment/
├── docker-compose.yml         # Ссылается на ../frontend и ../backend
├── nginx/
│   └── conf.d/
│       └── default.conf        # Конфигурация для localhost
└── ...

../frontend/                    # Отдельный репозиторий или папка
├── Dockerfile
└── ...

../backend/                     # Отдельный репозиторий или папка
├── Dockerfile
└── ...
```

В `docker-compose.yml` используются пути `../frontend` и `../backend`.

## Миграция на Submodules

Если у вас уже есть проекты в соседних папках:

1. **Создайте репозитории** для каждого проекта (если еще не созданы)
2. **Добавьте их как submodules:**

```bash
cd deployment

# Если проекты уже в Git репозиториях
git submodule add <URL-frontend> projects/frontend
git submodule add <URL-backend> projects/backend

# Обновите docker-compose.yml:
# context: ./projects/frontend
# context: ./projects/backend
```

3. **Обновите docker-compose.yml** для использования новых путей

## Best Practices

1. **Версионирование**: Используйте Git Submodules для контроля версий проектов
2. **Изоляция**: Каждый проект должен быть независимым
3. **Dockerfile**: Каждый проект содержит свой Dockerfile
4. **Конфигурация**: Nginx конфигурации хранятся в `nginx/conf.d/`
5. **Переменные окружения**: Используйте `.env` файлы для разных окружений
6. **Документация**: Документируйте структуру каждого проекта

## Troubleshooting

### Submodule не обновляется

```bash
# Принудительно обновить
git submodule update --init --recursive --force
```

### Проблемы с путями в docker-compose

Убедитесь, что пути в `context:` правильные относительно `docker-compose.yml`:
- `./projects/project1/frontend` - если проект в папке projects
- `../frontend` - если проект в родительской директории

### Проблемы с правами

```bash
sudo chown -R $USER:$USER nginx/logs
```

## Полезные команды

```bash
# Инициализация всех submodules
git submodule update --init --recursive

# Обновление всех submodules
git submodule update --remote

# Статус submodules
git submodule status

# Просмотр конфигурации docker-compose
docker-compose config

# Пересборка всех сервисов
docker-compose build --no-cache

# Очистка неиспользуемых ресурсов
docker system prune -a
```
