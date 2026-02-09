# Deployment Configuration

Гибкая конфигурация для развертывания проектов с использованием Docker Compose и Nginx.

**English:** [README](README.md) (main) · **Nginx:** [NGINX_GUIDE.md](NGINX_GUIDE.md) (подробнее про Nginx, SSL, порты)

> **Важно:** конфигурация **dev** (локальная разработка) и **prod** (сервер) может отличаться: разные compose-файлы, пути к проектам, конфиги Nginx, порты и наличие SSL. В этом README описаны оба варианта; при настройке смотрите соответствующий раздел.

## Архитектура

Этот репозиторий является **репозиторием-конфигом** (infrastructure/deploy), который:

- Содержит `docker-compose.yml` (prod) и `docker-compose.dev.yml` (dev)
- Управляет конфигурацией Nginx для маршрутизации (`nginx.conf` — prod, `nginx.dev.conf` — dev)
- Ссылается на проекты через относительные пути (`../go-angular-pg`, `../habits-api`, `../habits`, `../frontend`, `../backend` и т.д.)

**Принцип работы:**

- Каждый проект содержит свои `Dockerfile` в корне или подпапках
- Этот репозиторий содержит только инфраструктуру (docker-compose, nginx, CI)
- Проекты лежат в соседних папках относительно `deployment/` (submodules не используются)

> **Dev vs prod:** в prod используются пути вида `../go-angular-pg/...`, `../habits-api`, `../habits`; в dev — могут быть `../admin-panel-golang/...`, `../frontend`, `../backend`. Состав сервисов и порты тоже различаются.

## Структура (текущее состояние репозитория)

```
deployment/
├── docker-compose.yml          # Prod: все сервисы, nginx на 80/443
├── docker-compose.dev.yml     # Dev: локальная разработка, nginx на 8080
├── nginx/
│   ├── nginx.conf             # Prod: lifedream.tech, habits.lifedream.tech, HTTPS
│   ├── nginx.dev.conf         # Dev: localhost, HTTP, /habits/, /habits-api/
│   └── ssl/                   # Сертификаты (только prod; не в git)
│       └── .gitkeep
├── NGINX_GUIDE.md             # Подробный гайд по Nginx
├── .gitmodules.example        # Опционально, сейчас не используется
├── .github/
│   └── workflows/
│       └── deploy.yml         # CI: деплой на сервер по push в main/master
├── .dockerignore
└── .gitignore
```

Отдельной папки `nginx/conf.d/` в репозитории нет: один файл `nginx.conf` (prod) или `nginx.dev.conf` (dev).

> **Dev vs prod:** в prod Nginx монтирует весь `nginx.conf`; в dev в контейнер передаётся `nginx.dev.conf` как `conf.d/default.conf`. Маршруты и домены отличаются.

## Начальная настройка

### Проекты рядом с deployment (текущая схема)

Проекты лежат в родительской директории:

```
../
├── deployment/           # этот репо
├── go-angular-pg/        # client + app (prod)
├── admin-panel-golang/   # client + app (dev, если отличается)
├── habits-api/
├── habits/               # фронт habits (prod)
├── frontend/             # фронт habits (dev)
└── backend/              # API habits (dev)
```

Ничего дополнительно настраивать не нужно — в compose уже указаны `../...` пути.

## Быстрый старт

### Prod (сервер)

```bash
cd deployment

# При необходимости
cp .env.example .env
# Отредактируйте .env и положите SSL-сертификаты в nginx/ssl/

docker-compose up -d
docker-compose ps
```

### Dev (локальная разработка)

```bash
cd deployment

docker compose -f docker-compose.dev.yml up -d
```

Доступ: **http://localhost:8080**. Article — корень и `/api/`, Habits — `/habits/` и `/habits-api/`.

> **Dev vs prod:** в dev порт 8080 (чтобы не занимать 80/443); в prod — 80 и 443. В dev нет отдельного контейнера article_frontend — статика Article может отдаваться тем же контейнером, что и Nginx (зависит от docker-compose.dev.yml).

## Что разворачивается

Деплой поднимает **два приложения** и общий Nginx.

- **Приложение 1 — Привычки:** отдельный фронт-репо + отдельный бек-репо (два репозитория).
- **Приложение 2 — Основной сайт (статьи, чат):** один монорепо, внутри него и фронт (Angular), и бек (Go).

| Приложение | Репозитории | Контейнеры | Стек |
|------------|-------------|------------|------|
| **1. Привычки** | [habits-client](https://github.com/andreyDanilenko/habits-client.git) (фронт), [habits-api](https://github.com/andreyDanilenko/habits-api.git) (бек) | `habits_frontend`, `habits_api`, `habits_db` | Vue 3 FSD + Go Gin, PostgreSQL |
| **2. Основной сайт** | [go-angular-pg](https://github.com/andreyDanilenko/go-angular-pg.git) (монорепо: фронт и бек в одном репо) | `article_frontend`, `article_app`, `article_db` | Angular + Go, PostgreSQL (статьи, чат) |

Итого: **3 репозитория**, **2 приложения** (в монорепе одно приложение = один фронт + один бек).

На сервере ожидаются папки: `../habits` (clone habits-client), `../habits-api`, `../go-angular-pg`. Workflow клонирует/обновляет эти репозитории, затем выполняет `docker-compose build` и `docker-compose up -d`.

## Текущие сервисы (prod — docker-compose.yml)

| Сервис              | Описание                    | Сборка (context)        |
|---------------------|----------------------------|--------------------------|
| article_db          | PostgreSQL для Article     | image: postgres:17.4     |
| article_frontend    | Фронт основного домена     | ../go-angular-pg/client  |
| article_app         | API Article                | ../go-angular-pg/app     |
| habits_db           | PostgreSQL для Habits      | image: postgres:17.4     |
| habits_api          | API Habits                 | ../habits-api            |
| habits_frontend     | Фронт Habits               | ../habits                |
| nginx               | Reverse proxy, 80/443      | image: nginx:alpine      |

В dev (`docker-compose.dev.yml`) набор и пути к образам могут отличаться — см. сам файл.

## Добавление нового проекта

### Шаг 1: Добавить сервисы в docker-compose

В `docker-compose.yml` (и при необходимости в `docker-compose.dev.yml`) добавьте сервисы нового проекта по аналогии с `habits_*` / `article_*`.

### Шаг 2: Обновить Nginx

- **Prod:** в `nginx/nginx.conf` добавьте блоки `server` (или `location`) для нового домена/путей и при необходимости SSL.
- **Dev:** в `nginx/nginx.dev.conf` добавьте `location` для нового приложения (например `/new-app/` и `/new-app-api/`).

После правок перезапустите Nginx:

```bash
# Prod
docker-compose restart nginx

# Dev
docker compose -f docker-compose.dev.yml restart nginx
```

> **Dev vs prod:** маршруты и домены в dev (localhost, пути) и prod (отдельные домены, HTTPS) обычно разные — это нормально.

### Шаг 3: Зависимости Nginx

В соответствующем compose-файле в сервисе `nginx` в `depends_on` добавьте новые фронт/бэкенд контейнеры.

## Управление сервисами

```bash
# Остановка (prod)
docker-compose stop

# Остановка и удаление контейнеров
docker-compose down

# Dev
docker compose -f docker-compose.dev.yml down

# Пересборка одного сервиса (prod)
docker-compose build article_frontend
docker-compose up -d article_frontend

# Логи
docker-compose logs -f
docker-compose logs -f nginx
```

## SSL/HTTPS (prod)

1. Получите сертификаты (Let's Encrypt и т.п.).
2. Положите файлы в `nginx/ssl/` (папка в `.gitignore` — не коммитить ключи).
3. В `nginx/nginx.conf` указаны пути к `lifedream.tech` и `habits.lifedream.tech`; при добавлении доменов добавьте свои `ssl_certificate` / `ssl_certificate_key`.
4. Перезапуск: `docker-compose restart nginx`.

Подробнее — в **NGINX_GUIDE.md** (wildcard vs отдельные сертификаты, копирование на сервер).

> **Dev vs prod:** в dev SSL обычно не используется; в prod обязателен для доменов.

## CI/CD

В `.github/workflows/deploy.yml` настроен деплой при push в `main`/`master`: SSH на сервер, обновление репозиториев (deployment, habits-api, habits, go-angular-pg), затем `docker-compose down && build && up -d` (сборка с кэшем слоёв). Серверные пути и имена репозиториев зашиты в workflow — при отличии dev/prod окружений их можно вынести в переменные/секреты.

## Best Practices

1. **Dev и prod:** явно разделяйте конфиги (отдельные compose и nginx-файлы) и не полагайтесь на то, что они совпадают.
2. **Версионирование:** версии проектов фиксируются на сервере через `git pull` в нужных папках (submodules сейчас не используются).
3. **Dockerfile:** каждый проект собирает свой образ; инфраструктура только в deployment.
4. **Переменные окружения:** используйте `.env` для паролей и URL; не коммитить секреты.
5. **Документация:** структуру и отличия dev/prod документируйте в README и NGINX_GUIDE.md.

## Troubleshooting

### Проблемы с путями в docker-compose

Пути в `context:` заданы относительно каталога с `docker-compose.yml`. Проверьте:

- Prod: `../go-angular-pg/client`, `../habits-api`, `../habits` и т.д.
- Dev: могут быть `../admin-panel-golang/app`, `../frontend`, `../backend` — они могут отличаться от prod.

### Порт 80 занят

См. **NGINX_GUIDE.md** — раздел «Ошибка address already in use». В dev используется порт 8080, чтобы избежать конфликта.

### Права на файлы

```bash
sudo chown -R $USER:$USER nginx/logs
```

## Полезные команды

```bash
# Prod
docker-compose config
docker-compose build --no-cache
docker-compose up -d

# Dev
docker compose -f docker-compose.dev.yml config
docker compose -f docker-compose.dev.yml up -d --build

# Общая очистка
docker system prune -a
```
