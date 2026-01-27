# Инфраструктура для деплоя

Этот репозиторий содержит всю инфраструктуру для развертывания трех репозиториев:
- `api-project-marketplace` (admin-panel-golang) - админ-панель на `lifedream.tech`
- `backend` - основной backend API на `erp.lifedream.tech`
- `frontend` - фронтенд приложение на `erp.lifedream.tech`

## Структура на сервере

```
/root/project/
├── api-project-marketplace/    # Монорепа admin-panel-golang (уже существует)
├── backend/                    # Backend репозиторий (клонируется)
├── frontend/                   # Frontend репозиторий (клонируется)
└── deployment/                 # Этот репозиторий
    ├── docker-compose.yml      # Конфигурация всех сервисов
    ├── nginx/                  # Nginx конфигурация
    │   ├── nginx.conf
    │   └── conf.d/
    │       ├── lifedream.tech.conf      # Конфиг для основного домена
    │       └── erp.lifedream.tech.conf  # Конфиг для поддомена ERP
    ├── scripts/                # Скрипты для управления
    │   ├── setup-repositories.sh
    │   ├── update-repositories.sh
    │   ├── update-single-repo.sh
    │   └── deploy.sh
    ├── backend/                # Dockerfile для backend
    ├── frontend/               # Dockerfile для frontend
    └── .github/workflows/
        └── deploy.yml          # GitHub Actions для автоматического деплоя
```

## Как это работает

1. **Репозиторий инфраструктуры** клонируется на сервер в `/root/project/deployment/`
2. При деплое скрипты автоматически клонируют/обновляют репозитории в `/root/project/`
3. Docker Compose собирает и запускает все сервисы:
   - `nginx` - reverse proxy с SSL для обоих доменов
   - `admin-panel` - админ-панель (Go, порт 8080) на `lifedream.tech`
   - `backend` - основной backend (Go, порт 8081) на `erp.lifedream.tech`
   - `frontend` - фронтенд (Vue/Nginx) на `erp.lifedream.tech`
   - `postgres-admin` - БД для admin-panel
   - `postgres-backend` - БД для backend

## Быстрый старт

### 1. Настройка репозиториев

Отредактируйте скрипты и укажите правильные пути к вашим репозиториям:
- `scripts/setup-repositories.sh` - для backend и frontend
- `scripts/update-repositories.sh` - для всех репозиториев
- `scripts/update-single-repo.sh` - для одного репозитория

**Важно:** `api-project-marketplace` уже должен существовать на сервере, его не нужно клонировать.

### 2. Настройка DNS

Убедитесь, что DNS настроен для поддомена `erp.lifedream.tech`:
- Добавьте A-запись `erp.lifedream.tech` → IP сервера
- Или CNAME `erp` → `lifedream.tech`

### 3. Первый деплой на сервер

```bash
# На сервере
cd /root/project
git clone <your-deployment-repo> deployment
cd deployment

# Разместите SSL сертификаты (должны поддерживать erp.lifedream.tech)
cp /path/to/lifedream.tech.crt nginx/ssl/
cp /path/to/lifedream.tech.key nginx/ssl/

# Настройка репозиториев (клонирует backend и frontend)
bash scripts/setup-repositories.sh

# Запуск
docker-compose up -d --build
```

### 4. Автоматический деплой

#### 4.1. Деплой инфраструктуры (deployment)

После настройки GitHub Secrets, автоматический деплой будет работать при пуше в `master`/`main` репозитория `deployment`.

При обновлении репозитория `deployment`:
- Обновляются все репозитории (api-project-marketplace, backend, frontend)
- Перезапускаются все контейнеры

#### 4.2. Деплой отдельных репозиториев

**Важно:** Для автоматического деплоя при изменении `backend`, `frontend` или `admin-panel-golang` нужно настроить GitHub Actions в каждом репозитории.

**Шаги:**

1. Скопируйте примеры workflows из `deployment/.github/workflows/`:
   - `deploy-backend.yml.example` → в репозиторий `backend/.github/workflows/deploy.yml`
   - `deploy-frontend.yml.example` → в репозиторий `frontend/.github/workflows/deploy.yml`
   - `deploy-admin-panel.yml.example` → в репозиторий `admin-panel-golang/.github/workflows/deploy.yml`

2. Настройте GitHub Secrets в каждом репозитории:
   - `SERVER_HOST`
   - `SERVER_USER`
   - `DEPLOY_SECRET_KEY`

3. При пуше в `main`/`master` каждого репозитория:
   - Обновляется только этот репозиторий на сервере
   - Перезапускаются только соответствующие контейнеры

**Пример:** При изменении в `backend`:
- Обновляется `/root/project/backend/`
- Перезапускаются контейнеры `backend` и `postgres-backend`
- Остальные сервисы не затрагиваются

## Подробная документация

- [DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md) - полный чеклист для настройки
- [CI_CD_SETUP.md](./CI_CD_SETUP.md) - настройка автоматического деплоя для каждого репозитория

## Важные замечания

⚠️ **Структура на сервере:** Репозитории находятся на одном уровне в `/root/project/`, а не внутри deployment
⚠️ **SSL сертификаты** должны поддерживать оба домена: `lifedream.tech` и `erp.lifedream.tech`
⚠️ **Порты:** admin-panel использует 8080, backend использует 8081 (избегает конфликтов)
⚠️ **Базы данных:** Две отдельные БД - `postgres-admin` для admin-panel и `postgres-backend` для backend
⚠️ **Пароли БД** нужно изменить в `docker-compose.yml` на безопасные
⚠️ **GitHub Secrets** должны быть настроены для автоматического деплоя
⚠️ **DNS** должен быть настроен для поддомена `erp.lifedream.tech`
