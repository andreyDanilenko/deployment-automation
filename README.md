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

Each project has its own README: [Main site (go-angular-pg)](../admin-panel-golang/README.md) (or in your clone: `go-angular-pg`), [Habits frontend](../frontend/README.md), [Habits API](../backend/README.md) (or `habits-api`).

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
   docker-compose up -d
   ```
   Compose builds images from `../go-angular-pg`, `../habits`, `../habits-api` and runs Nginx on 80/443.

**Dev (local):** use `docker-compose.dev.yml`; app is on `http://localhost:8080` (main site at `/`, habits at `/habits/`, API at `/habits-api/`).

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

```bash
docker-compose up -d
docker-compose down
docker-compose build
docker-compose logs -f nginx
```
