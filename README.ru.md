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

Описание и стек каждого проекта — в его README: [Основной сайт](https://github.com/andreyDanilenko/go-angular-pg/README.md) (или `go-angular-pg`), [Фронт Привычки](https://github.com/andreyDanilenko/habits-client/frontend/README.md), [API Привычки](https://github.com/andreyDanilenko/habits-api/backend/README.md) (или `habits-api`).

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
   docker-compose up -d
   ```
   Compose соберёт образы из `../go-angular-pg`, `../habits`, `../habits-api` и поднимет Nginx на 80/443.

**Локально (dev):** использовать `docker-compose.dev.yml`; приложение на `http://localhost:8080` (основной сайт — `/`, привычки — `/habits/`, API — `/habits-api/`).

**CI:** в `.github/workflows/deploy.yml` по push в `main`/`master` — SSH на сервер, pull всех четырёх репо, затем `docker-compose build && docker-compose up -d`.

---

## Что запускается (контейнеры)

| Сервис | Назначение |
|--------|------------|
| `article_frontend`, `article_app`, `article_db` | Основной сайт (Angular + Go + Postgres) |
| `habits_frontend`, `habits_api`, `habits_db` | ERP Привычки (Vue + Go + Postgres) |
| `nginx` | Reverse proxy, 80/443 |

---

## Полезные команды

```bash
docker-compose up -d
docker-compose down
docker-compose build
docker-compose logs -f nginx
```
