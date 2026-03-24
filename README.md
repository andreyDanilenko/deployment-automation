# Deployment — main repo

This repo deploys **two applications** behind one Nginx.

**Apps:** [lifedream.tech](https://lifedream.tech) (main site) · [habits.lifedream.tech](https://habits.lifedream.tech) (ERP / Habits)

**Русский:** [README.ru.md](README.ru.md)

---

## Projects we deploy

| App | URL | What it is | Repos | Stack |
|-----|-----|------------|-------|--------|
| **Main site** | [lifedream.tech](https://lifedream.tech) | Articles + test chat | [go-angular-pg](https://github.com/andreyDanilenko/go-angular-pg) (monorepo) | **Front:** Angular, TypeScript · **Back:** Go, PostgreSQL |
| **Habits (ERP)** | [habits.lifedream.tech](https://habits.lifedream.tech) | ERP; first module = Habits | [habits-client](https://github.com/andreyDanilenko/habits-client), [habits-api](https://github.com/andreyDanilenko/habits-api) | **Front:** Vue 3, Vite, Pinia, FSD · **Back:** Go, Gin, PostgreSQL |

- **lifedream.tech** — main site: articles and a test chat (one monorepo: Angular + Go).
- **habits.lifedream.tech** — ERP with the first module “Habits” (habit tracker); front and back are separate repos.

---

## How to deploy everything

1. **Clone repos** next to each other (no submodules):
   ```
   parent/
   ├── deployment/     ← this repo (main)
   ├── go-angular-pg/  ← main site (or admin-panel-golang)
   ├── habits/         ← clone of habits-client
   └── habits-api/     ← clone of habits-api
   ```

2. **SSL (prod):** put certs in `deployment/nginx/ssl/` (see `nginx/nginx.conf` for paths).

3. **From deployment folder:**
   ```bash
   cd deployment
   docker compose up -d
   ```
   **Важно:** используйте `docker compose` (v2), а не `docker-compose` (v1) — иначе ошибка `ContainerConfig`. Или запустите `./deploy.sh`.

**Dev (local):** use `docker-compose.dev.yml`; app is on `http://localhost:8080` (main site at `/`, habits at `/habits/`, API at `/habits-api/`).

**Local webhooks (Telegram, etc.):** use a tunnel to public HTTPS — see [docs/DEV_TUNNEL.ru.md](docs/DEV_TUNNEL.ru.md) (Russian, short).

**Telegram bind — local + prod checklist (Russian):** [docs/TELEGRAM_BIND_LOCAL_AND_PROD.ru.md](docs/TELEGRAM_BIND_LOCAL_AND_PROD.ru.md).

**CI:** `.github/workflows/deploy.yml` — on push to `main`/`master` it SSHs to the server, pulls all four repos, then `docker-compose build && docker-compose up -d`.

---

## What runs (containers)

| Service | Role |
|---------|------|
| `article_frontend`, `article_app`, `article_db` | Main site (Angular + Go + Postgres) |
| `habits_frontend`, `habits_api`, `habits_db` | Habits ERP (Vue + Go + Postgres) |
| `nginx` | Reverse proxy, 80/443 |

---

## Useful commands

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

## Local vs Docker: network and env

If services run in different environments (some in Docker, some local), hosts must differ.

| From -> To | URL/Host | Env example |
|---|---|---|
| Docker -> Docker (same `docker compose`) | service name | `REDIS_URL=redis://redis:6379` |
| Local -> Docker | `localhost:published_port` | `REDIS_URL=redis://localhost:6379` |
| Docker -> Local | `host.docker.internal:port` | `N8N -> nest-satellite: http://host.docker.internal:3001/...` |

### Mode 1: all in Docker (recommended)

- `n8n` calls `nest_satellite`: `http://nest_satellite:3001/internal/notifications/send` and `.../internal/integrations/telegram/confirm` (Nest proxies to Go)
- `nest_satellite` to habits-api (Go): `HABITS_API_BASE_URL=http://habits_api:8080`
- `nest_satellite` calls Redis: `redis://redis:6379`
- Internal endpoint key:
  - `INTERNAL_NOTIFICATIONS_API_KEY` in `nest_satellite`
  - same key in `n8n` header `x-internal-api-key`

### Mode 2: `nest-satellite` local, `n8n` in Docker

- `nest-satellite` locally:
  - `REDIS_URL=redis://localhost:6379`
  - `INTERNAL_NOTIFICATIONS_API_KEY=<same-key>`
- In `n8n`, HTTP Request URL:
  - `http://host.docker.internal:3001/internal/notifications/send`
- Header:
  - `x-internal-api-key: <same-key>`
