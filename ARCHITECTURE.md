# Архитектура Deployment

## Концепция репозитория-конфига

Этот репозиторий является **централизованным репозиторием инфраструктуры** (infrastructure/deploy репозиторий), который управляет развертыванием нескольких независимых проектов.

## Принципы архитектуры

### 1. Разделение ответственности

```
┌─────────────────────────────────────────┐
│  Репозиторий-конфиг (deployment)        │
│  - docker-compose.yml                   │
│  - nginx/ конфигурация                  │
│  - скрипты развертывания                │
└─────────────────────────────────────────┘
           │ ссылается на
           ▼
┌─────────────────────────────────────────┐
│  Проект 1 (отдельный репозиторий)      │
│  - frontend/                            │
│    └── Dockerfile                       │
│  - backend/                             │
│    └── Dockerfile                       │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  Проект 2 (отдельный репозиторий)      │
│  - Dockerfile                           │
└─────────────────────────────────────────┘
```

**Ключевые принципы:**
- Каждый проект **автономен** и содержит свои Dockerfile
- Репозиторий-конфиг **не содержит** исходный код проектов
- Проекты подтягиваются через **Git Submodules** или копирование

### 2. Механизм подтягивания проектов

#### Вариант A: Git Submodules (Рекомендуется)

```bash
# В репозитории-конфиге
git submodule add <URL-проекта-1> projects/project1
git submodule add <URL-проекта-2> projects/project2
```

**Преимущества:**
- ✅ Контроль версий проектов
- ✅ Связь с исходными репозиториями
- ✅ Возможность фиксации конкретных версий
- ✅ Автоматическое обновление

**Недостатки:**
- ⚠️ Требует понимания Git Submodules
- ⚠️ Немного сложнее для новичков

#### Вариант B: Прямое копирование

```bash
# Просто скопировать папки проектов
cp -r /path/to/project1 projects/project1
```

**Преимущества:**
- ✅ Простота
- ✅ Не требует знания Git Submodules

**Недостатки:**
- ❌ Потеря связи с исходными репозиториями
- ❌ Нет контроля версий
- ❌ Ручное обновление

### 3. Структура docker-compose.yml

```yaml
services:
  project1-frontend:
    build:
      context: ./projects/project1/frontend  # Путь к проекту
      dockerfile: Dockerfile                 # Dockerfile в проекте
    # ...
```

**Правила:**
- `context:` указывает на директорию проекта (или подпапку)
- `dockerfile:` указывает на Dockerfile в этой директории
- Пути относительно `docker-compose.yml`

## Структура директорий

### Текущая структура (для разработки)

```
myProject/
├── frontend/              # Vue проект
│   ├── Dockerfile
│   └── ...
├── backend/               # Go проект
│   ├── Dockerfile
│   └── ...
└── deployment/           # Репозиторий-конфиг
    ├── docker-compose.yml  # Ссылается на ../frontend, ../backend
    └── nginx/
```

### Структура с Git Submodules

```
deployment/               # Репозиторий-конфиг
├── docker-compose.yml
├── nginx/
├── projects/             # Git Submodules
│   ├── project1/         # Submodule → репозиторий проекта 1
│   │   ├── frontend/
│   │   │   └── Dockerfile
│   │   └── backend/
│   │       └── Dockerfile
│   └── project2/         # Submodule → репозиторий проекта 2
│       └── Dockerfile
└── .gitmodules           # Конфигурация submodules
```

## Алгоритм работы

### Инициализация

1. **Клонировать репозиторий-конфиг:**
   ```bash
   git clone --recursive <URL-репозитория-конфига>
   ```

2. **Или инициализировать submodules:**
   ```bash
   git clone <URL-репозитория-конфига>
   cd deployment
   git submodule update --init --recursive
   ```

3. **Настроить переменные окружения:**
   ```bash
   cp .env.example .env
   ```

4. **Запустить:**
   ```bash
   docker-compose up -d
   ```

### Добавление нового проекта

1. **Добавить проект как Submodule:**
   ```bash
   git submodule add <URL-проекта> projects/new-project
   ```

2. **Добавить в docker-compose.yml:**
   ```yaml
   services:
     new-project-frontend:
       build:
         context: ./projects/new-project/frontend
         dockerfile: Dockerfile
   ```

3. **Создать Nginx конфигурацию:**
   ```bash
   cp nginx/conf.d/template.conf.example nginx/conf.d/new-project.conf
   ```

4. **Обновить зависимости:**
   ```yaml
   nginx:
     depends_on:
       - new-project-frontend
   ```

5. **Запустить:**
   ```bash
   docker-compose up -d --build
   ```

### Обновление проектов

```bash
# Обновить все проекты до последних версий
git submodule update --remote

# Обновить конкретный проект
git submodule update --remote projects/project1

# Зафиксировать версию
git add projects/project1
git commit -m "Update project1 to latest"
```

## Nginx маршрутизация

### Структура конфигураций

```
nginx/
├── nginx.conf              # Основная конфигурация
└── conf.d/                 # Конфигурации проектов
    ├── default.conf        # Текущий проект
    ├── project1.conf       # Проект 1
    ├── project2.conf       # Проект 2
    └── template.conf.example
```

### Принцип работы

1. **Nginx читает все .conf файлы** из `conf.d/`
2. **Каждый файл** описывает маршрутизацию для одного проекта
3. **server_name** определяет домен проекта
4. **proxy_pass** указывает на Docker сервис

### Пример конфигурации

```nginx
# nginx/conf.d/project1.conf
server {
    listen 80;
    server_name project1.example.com;

    location / {
        proxy_pass http://project1-frontend:3000;
    }

    location /api {
        proxy_pass http://project1-backend:8080;
    }
}
```

## Масштабирование

### Горизонтальное масштабирование

```yaml
services:
  project1-backend:
    # ...
    deploy:
      replicas: 3
```

С балансировкой в Nginx:

```nginx
upstream project1-backend {
    least_conn;
    server project1-backend:8080;
    server project1-backend_2:8080;
    server project1-backend_3:8080;
}
```

### Вертикальное масштабирование

Добавление новых проектов:
1. Добавить submodule
2. Добавить в docker-compose.yml
3. Создать Nginx конфигурацию
4. Перезапустить

## Изоляция проектов

### Сетевой уровень

```yaml
networks:
  app-network:
    driver: bridge
```

Все сервисы в одной сети, но изолированы по контейнерам.

### Уровень данных

Каждый проект может иметь:
- Свою БД (отдельный контейнер postgres)
- Свои volumes
- Свои переменные окружения

### Уровень конфигурации

- Отдельные Nginx конфигурации
- Отдельные секции в docker-compose.yml
- Отдельные .env файлы (опционально)

## Best Practices

### 1. Версионирование

- Фиксируйте версии проектов через коммиты submodules
- Используйте теги для production версий
- Документируйте используемые версии

### 2. Структура проектов

Убедитесь, что каждый проект имеет:
- Dockerfile в корне или подпапках
- README.md с инструкциями
- .dockerignore для оптимизации сборки

### 3. Конфигурация

- Используйте .env файлы для разных окружений
- Не коммитьте секреты в Git
- Используйте Docker secrets для production

### 4. Мониторинг

- Настройте health checks для всех сервисов
- Используйте логирование
- Настройте мониторинг (Prometheus, Grafana)

### 5. Безопасность

- Используйте SSL/TLS для production
- Настройте firewall правила
- Регулярно обновляйте образы
- Используйте минимальные базовые образы

## Миграция на микросервисы

При переходе на микросервисы:

1. **Выделите сервисы** из проектов:**
   - Каждый сервис = отдельный submodule
   - Или отдельный репозиторий

2. **Обновите docker-compose.yml:**
   ```yaml
   services:
     user-service:
       build:
         context: ./services/user-service
     product-service:
       build:
         context: ./services/product-service
   ```

3. **Настройте service discovery:**
   - Используйте Docker DNS
   - Или внешний service mesh (Istio, Consul)

4. **Настройте API Gateway:**
   - Nginx как API Gateway
   - Или выделенный сервис (Kong, Traefik)

## Troubleshooting

### Проблемы с путями

**Симптом:** Docker не находит Dockerfile

**Решение:**
- Проверьте пути в `context:` относительно `docker-compose.yml`
- Используйте относительные пути: `./projects/project1/frontend`
- Проверьте наличие Dockerfile в указанной директории

### Проблемы с Submodules

**Симптом:** Submodule пустой или не обновляется

**Решение:**
```bash
git submodule update --init --recursive --force
git submodule update --remote
```

### Проблемы с Nginx

**Симптом:** Nginx не видит новые сервисы

**Решение:**
1. Проверьте, что сервисы запущены: `docker-compose ps`
2. Проверьте конфигурацию: `docker-compose exec nginx nginx -t`
3. Перезагрузите: `docker-compose restart nginx`

## Полезные ссылки

- [Git Submodules Documentation](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Nginx Documentation](https://nginx.org/en/docs/)


