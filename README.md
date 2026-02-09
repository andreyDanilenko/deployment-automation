# Deployment Configuration

Flexible configuration for deploying projects with Docker Compose and Nginx.

**Русский:** [README на русском](README.ru.md) · **Nginx:** [NGINX_GUIDE.md](NGINX_GUIDE.md) (Nginx details, SSL, troubleshooting)

> **Note:** **dev** (local) and **prod** (server) configs can differ: different compose files, project paths, Nginx configs, ports, SSL. This README covers both; see the relevant section when setting up.

## Architecture

This repo is the **config/infrastructure** repo. It:

- Provides `docker-compose.yml` (prod) and `docker-compose.dev.yml` (dev)
- Holds Nginx config for routing (`nginx.conf` — prod, `nginx.dev.conf` — dev)
- References projects via relative paths (`../go-angular-pg`, `../habits-api`, `../habits`, etc.)

**How it works:**

- Each app has its own `Dockerfile` in its repo
- This repo only has infrastructure (compose, nginx, CI)
- Projects live in sibling folders next to `deployment/` (no Git submodules)

> **Dev vs prod:** prod uses paths like `../go-angular-pg/...`, `../habits-api`, `../habits`; dev may use `../admin-panel-golang/...`, `../frontend`, `../backend`. Service set and ports differ too.

## Repo structure

```
deployment/
├── docker-compose.yml          # Prod: all services, nginx on 80/443
├── docker-compose.dev.yml      # Dev: local, nginx on 8080
├── nginx/
│   ├── nginx.conf             # Prod: lifedream.tech, habits.lifedream.tech, HTTPS
│   ├── nginx.dev.conf         # Dev: localhost, HTTP, /habits/, /habits-api/
│   └── ssl/                   # Certificates (prod only; not in git)
│       └── .gitkeep
├── NGINX_GUIDE.md             # Nginx details, SSL, ports — see [NGINX_GUIDE.md](NGINX_GUIDE.md)
├── .gitmodules.example        # Optional, not used currently
├── .github/workflows/deploy.yml
├── .dockerignore
└── .gitignore
```

Single Nginx config file per environment (no `nginx/conf.d/`).

> **Dev vs prod:** prod mounts full `nginx.conf`; dev uses `nginx.dev.conf` as `conf.d/default.conf`. Routes and domains differ.

## Initial setup

### Projects next to deployment (current setup)

Projects live in the parent directory:

```
../
├── deployment/           # this repo
├── go-angular-pg/        # client + app (prod)
├── admin-panel-golang/   # client + app (dev, if different)
├── habits-api/
├── habits/               # habits frontend (prod)
├── frontend/             # habits frontend (dev)
└── backend/              # habits API (dev)
```

No extra setup — compose already uses `../...` paths.

## Quick start

### Prod (server)

```bash
cd deployment

# If needed
cp .env.example .env
# Edit .env and place SSL certs in nginx/ssl/

docker-compose up -d
docker-compose ps
```

### Dev (local)

```bash
cd deployment

docker compose -f docker-compose.dev.yml up -d
```

Access: **http://localhost:8080**. Article — `/` and `/api/`, Habits — `/habits/` and `/habits-api/`.

> **Dev vs prod:** dev uses port 8080; prod uses 80 and 443. See [NGINX_GUIDE.md](NGINX_GUIDE.md) for ports and “address already in use”.

## What gets deployed

**Two applications** plus shared Nginx.

- **App 1 — Habits:** separate frontend repo + separate backend repo (two repos).
- **App 2 — Main site (articles, chat):** one monorepo with frontend (Angular) and backend (Go).

| Application | Repositories | Containers | Stack |
|-------------|--------------|------------|--------|
| **1. Habits** | [habits-client](https://github.com/andreyDanilenko/habits-client.git) (front), [habits-api](https://github.com/andreyDanilenko/habits-api.git) (back) | `habits_frontend`, `habits_api`, `habits_db` | Vue 3 FSD + Go Gin, PostgreSQL |
| **2. Main site** | [go-angular-pg](https://github.com/andreyDanilenko/go-angular-pg.git) (monorepo: front + back) | `article_frontend`, `article_app`, `article_db` | Angular + Go, PostgreSQL (articles, chat) |

**Total:** 3 repos, 2 applications (monorepo = one app = one front + one back).

Server expects: `../habits` (clone habits-client), `../habits-api`, `../go-angular-pg`. The workflow clones/updates these, then runs `docker-compose build` and `docker-compose up -d`.

## Services (prod — docker-compose.yml)

| Service           | Description              | Build context        |
|-------------------|--------------------------|----------------------|
| article_db         | PostgreSQL for Article   | image: postgres:17.4 |
| article_frontend   | Main site frontend       | ../go-angular-pg/client |
| article_app        | Article API              | ../go-angular-pg/app |
| habits_db          | PostgreSQL for Habits    | image: postgres:17.4 |
| habits_api         | Habits API               | ../habits-api        |
| habits_frontend    | Habits frontend          | ../habits            |
| nginx              | Reverse proxy, 80/443    | image: nginx:alpine  |

Dev (`docker-compose.dev.yml`) may use different services/paths — check that file.

## Adding a new project

### Step 1: Add services to docker-compose

In `docker-compose.yml` (and `docker-compose.dev.yml` if needed) add services like `habits_*` / `article_*`.

### Step 2: Update Nginx

- **Prod:** in `nginx/nginx.conf` add `server` / `location` for the new domain/paths and SSL if needed.
- **Dev:** in `nginx/nginx.dev.conf` add `location` for the new app (e.g. `/new-app/`, `/new-app-api/`).

Restart Nginx:

```bash
# Prod
docker-compose restart nginx

# Dev
docker compose -f docker-compose.dev.yml restart nginx
```

See [NGINX_GUIDE.md](NGINX_GUIDE.md) for config roles and SSL.

### Step 3: Nginx dependencies

In the compose file, add the new frontend/backend containers to `nginx`’s `depends_on`.

## Managing services

```bash
# Stop (prod)
docker-compose stop

# Down
docker-compose down

# Dev
docker compose -f docker-compose.dev.yml down

# Rebuild one service (prod)
docker-compose build article_frontend
docker-compose up -d article_frontend

# Logs
docker-compose logs -f
docker-compose logs -f nginx
```

## SSL/HTTPS (prod)

1. Obtain certificates (e.g. Let’s Encrypt).
2. Place files in `nginx/ssl/` (folder is in `.gitignore` — do not commit keys).
3. In `nginx/nginx.conf` paths for `lifedream.tech` and `habits.lifedream.tech` are set; add your `ssl_certificate` / `ssl_certificate_key` for new domains.
4. Restart: `docker-compose restart nginx`.

Details: [NGINX_GUIDE.md](NGINX_GUIDE.md) (wildcard vs per-domain certs, copying to server).

> **Dev vs prod:** SSL is typically not used in dev; required in prod.

## CI/CD

`.github/workflows/deploy.yml`: on push to `main`/`master`, SSH to server, update repos (deployment, habits-api, habits, go-angular-pg), then `docker-compose down && build && up -d` (build with layer cache). Server paths and repo names are in the workflow; move to variables/secrets if you need different dev/prod.

## Best practices

1. **Dev and prod:** keep configs separate (different compose and nginx files); don’t assume they match.
2. **Versions:** project versions are fixed on the server via `git pull` in each folder (submodules not used).
3. **Dockerfile:** each project builds its own image; only infrastructure lives in deployment.
4. **Env:** use `.env` for passwords and URLs; don’t commit secrets.
5. **Docs:** keep [README](README.md) and [README.ru.md](README.ru.md) and [NGINX_GUIDE.md](NGINX_GUIDE.md) in sync for structure and dev/prod differences.

## Troubleshooting

### docker-compose paths

`context:` paths are relative to the directory containing `docker-compose.yml`. Check:

- Prod: `../go-angular-pg/client`, `../habits-api`, `../habits`, etc.
- Dev: may use `../admin-panel-golang/app`, `../frontend`, `../backend` — can differ from prod.

### Port 80 in use

See [NGINX_GUIDE.md](NGINX_GUIDE.md) — “address already in use”. Dev uses port 8080 to avoid conflict.

### File permissions

```bash
sudo chown -R $USER:$USER nginx/logs
```

## Useful commands

```bash
# Prod
docker-compose config
docker-compose build --no-cache
docker-compose up -d

# Dev
docker compose -f docker-compose.dev.yml config
docker compose -f docker-compose.dev.yml up -d --build

# Cleanup
docker system prune -a
```
