# Deployment — главный репозиторий

Из этого репозитория разворачиваются **два приложения** под одним Nginx.

**Приложения:** [lifedream.tech](https://lifedream.tech) (основной сайт) · [habits.lifedream.tech](https://habits.lifedream.tech) (ERP / Привычки)

**English:** [README.md](README.md)

---

## Какие проекты разворачиваем

| Приложение | URL | Что это | Репозитории | Стек |
|------------|-----|--------|-------------|------|
| **Основной сайт** | [lifedream.tech](https://lifedream.tech) | Статьи и тестовый чат | [go-angular-pg](https://github.com/andreyDanilenko/go-angular-pg) (монорепо) | **Фронт:** Angular, TypeScript · **Бэк:** Go, PostgreSQL |
| **Привычки (ERP)** | [habits.lifedream.tech](https://habits.lifedream.tech) | ERP; первый модуль — привычки | [habits-client](https://github.com/andreyDanilenko/habits-client), [habits-api](https://github.com/andreyDanilenko/habits-api) | **Фронт:** Vue 3, Vite, Pinia, FSD · **Бэк:** Go, Gin, PostgreSQL |

- **lifedream.tech** — основной сайт: статьи и тест чата (один монорепо: Angular + Go).
- **habits.lifedream.tech** — ERP с первым модулем «Привычки»; фронт и бэк — отдельные репо.
---

## Как развернуть всё

1. **Клонировать репозитории** рядом (submodules не используются):
   ```
   parent/
   ├── deployment/     ← этот репо (главный)
   ├── go-angular-pg/  ← основной сайт (или admin-panel-golang)
   ├── habits/         ← клон habits-client
   └── habits-api/     ← клон habits-api
   ```

2. **SSL (прод):** положить сертификаты в `deployment/nginx/ssl/` (пути в `nginx/nginx.conf`).

3. **Из папки deployment:**
   ```bash
   cd deployment
   docker compose up -d
   ```
   **Важно:** используйте `docker compose` (v2), а не `docker-compose` (v1) — иначе ошибка `ContainerConfig`. Или запустите `./deploy.sh`.

**Локально (dev):** использовать `docker-compose.dev.yml`; приложение на `http://localhost:8080` (основной сайт — `/`, привычки — `/habits/`, API — `/habits-api/`).

**Локальные webhook (Telegram и др.):** нужен туннель на публичный HTTPS — см. [docs/DEV_TUNNEL.ru.md](docs/DEV_TUNNEL.ru.md).

**CI:** в `.github/workflows/deploy.yml` по push в `main`/`master` — SSH на сервер, pull всех четырёх репо, затем `docker-compose build && docker-compose up -d`.

**n8n + Google integration:** см. `N8N_GOOGLE_INTEGRATION.ru.md`.
**n8n + Telegram MVP:** см. `docs/TELEGRAM_MVP.ru.md`.
**n8n + Telegram auto-connect (/start):** см. `docs/TELEGRAM_BIND_FLOW.ru.md`.
**Telegram привязка — тест локально и прод (чеклист):** см. [docs/TELEGRAM_BIND_LOCAL_AND_PROD.ru.md](docs/TELEGRAM_BIND_LOCAL_AND_PROD.ru.md).
**Прод на VPS, `.env`, SSL и cron:** см. [docs/PROD_VPS_CHECKLIST.ru.md](docs/PROD_VPS_CHECKLIST.ru.md).
**n8n + Main Gateway (clean v2):** см. `docs/N8N_MAIN_GATEWAY.ru.md`.
**Интеграции (полная схема и roadmap):** см. `docs/INTEGRATIONS_SYSTEM_GUIDE.ru.md`.

---

## Что запускается (контейнеры)

| Сервис | Назначение |
|--------|------------|
| `article_frontend`, `article_app`, `article_db` | Основной сайт (Angular + Go + Postgres) |
| `habits_frontend`, `habits_api`, `habits_db` | ERP Привычки (Vue + Go + Postgres) |
| `nginx` | Reverse proxy, 80/443 |

---

## Полезные команды

Используйте **docker compose** (v2), не docker-compose — v1 даёт ошибку ContainerConfig с новыми образами.

```bash
docker compose up -d
docker compose down
docker compose build
docker compose logs -f nginx

# Или скрипт:
./deploy.sh
```

---

## Local vs Docker: сеть и env

Если сервисы запущены в разных средах (часть в Docker, часть локально), адреса должны быть разными.

| Откуда -> Куда | URL/Host | Пример переменной |
|---|---|---|
| Docker -> Docker (в одном `docker compose`) | имя сервиса | `REDIS_URL=redis://redis:6379` |
| Local -> Docker | `localhost:published_port` | `REDIS_URL=redis://localhost:6379` |
| Docker -> Local | `host.docker.internal:port` | `N8N -> nest-satellite: http://host.docker.internal:3001/...` |

### Режим 1: всё в Docker (рекомендуется)

- `n8n` обращается к `nest_satellite` по: `http://nest_satellite:3001/internal/notifications/send` и `.../internal/integrations/telegram/confirm` (прокси в Go)
- `nest_satellite` к Go (habits-api): `HABITS_API_BASE_URL=http://habits_api:8080`
- `nest_satellite` обращается к Redis по: `redis://redis:6379`
- Ключ для внутреннего endpoint:
  - `INTERNAL_NOTIFICATIONS_API_KEY` в `nest_satellite`
  - тот же ключ в header `x-internal-api-key` в `n8n`

### Режим 2: `nest-satellite` локально, `n8n` в Docker

- `nest-satellite` локально:
  - `REDIS_URL=redis://localhost:6379`
  - `INTERNAL_NOTIFICATIONS_API_KEY=<same-key>`
- В `n8n` URL для HTTP Request:
  - `http://host.docker.internal:3001/internal/notifications/send`
- Header:
  - `x-internal-api-key: <same-key>`
