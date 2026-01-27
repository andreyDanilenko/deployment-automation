# Чеклист для успешного деплоя инфраструктуры

Этот документ содержит список того, что нужно настроить перед первым деплоем.

## 1. Настройка репозиториев

### 1.1. Обновить пути к репозиториям в скриптах

В следующих файлах нужно указать правильные пути к вашим репозиториям:

- `scripts/setup-repositories.sh` - замените `YOUR_USERNAME` на ваше имя пользователя GitHub
- `scripts/update-repositories.sh` - замените `YOUR_USERNAME` и укажите правильные ветки (master/main)
- `scripts/update-single-repo.sh` - аналогично

**Пример для `scripts/setup-repositories.sh`:**
```bash
declare -A REPOS=(
    ["backend"]="git@github.com:YOUR_USERNAME/backend.git:main"
    ["frontend"]="git@github.com:YOUR_USERNAME/frontend.git:main"
)
```

**Пример для `scripts/update-repositories.sh` и `scripts/update-single-repo.sh`:**
```bash
declare -A REPOS=(
    ["api-project-marketplace"]="master:git@github.com:andreyDanilenko/admin-panel-golang.git"
    ["backend"]="main:git@github.com:YOUR_USERNAME/backend.git"
    ["frontend"]="main:git@github.com:YOUR_USERNAME/frontend.git"
)
```

**Важно:** 
- `api-project-marketplace` уже существует на сервере, его не нужно клонировать
- `backend` и `frontend` клонируются в `/root/project/` при первом деплое

### 1.2. Убедиться, что все репозитории доступны по SSH

На сервере должен быть настроен SSH ключ для доступа к GitHub:
- Ключ должен быть в `~/.ssh/github_keys`
- Ключ должен быть добавлен в GitHub аккаунт
- Проверка: `ssh -T git@github.com` должна работать

## 2. Настройка DNS

### 2.1. Настройка поддомена erp.lifedream.tech

Убедитесь, что DNS настроен для поддомена:
- Добавьте A-запись для `erp.lifedream.tech` → IP сервера (62.113.103.222)
- Или добавьте CNAME запись `erp` → `lifedream.tech`

Проверка:
```bash
dig erp.lifedream.tech
# или
nslookup erp.lifedream.tech
```

## 3. Настройка сервера

### 3.1. Структура директорий на сервере

На сервере должна быть следующая структура:
```
/root/project/
├── api-project-marketplace/  (монорепа admin-panel-golang, уже существует)
│   ├── app/
│   ├── client/
│   ├── docker-compose.yml
│   └── nginx/
├── backend/  (клонируется автоматически)
├── frontend/  (клонируется автоматически)
└── deployment/  (репозиторий инфраструктуры)
    ├── docker-compose.yml
    ├── nginx/
    └── scripts/
```

**Важно:** 
- `api-project-marketplace` уже должен существовать на сервере
- `backend` и `frontend` клонируются автоматически при первом деплое
- `deployment` - это репозиторий инфраструктуры, который вы клонируете

### 3.2. Установка Docker и Docker Compose

Убедитесь, что на сервере установлены:
- Docker
- Docker Compose

Проверка:
```bash
docker --version
docker-compose --version
```

### 3.3. SSL сертификаты

**Важно:** SSL сертификат должен поддерживать поддомен `erp.lifedream.tech`. 
Если используется Let's Encrypt, можно использовать wildcard сертификат `*.lifedream.tech` или добавить оба домена в один сертификат.

SSL сертификаты должны быть размещены в:
```
/root/project/api-project-marketplace/nginx/ssl/
├── lifedream.tech.crt
└── lifedream.tech.key
```

**Важно:** Эти файлы не должны попадать в git репозиторий (добавлены в .gitignore).

### 3.4. Права доступа

Убедитесь, что скрипты имеют права на выполнение:
```bash
chmod +x scripts/*.sh
```

## 4. Настройка GitHub Secrets

В настройках репозитория инфраструктуры (Settings → Secrets and variables → Actions) должны быть настроены:

- `SERVER_HOST` - IP адрес или домен сервера (например: `62.113.103.222`)
- `SERVER_USER` - пользователь для SSH (обычно `root`)
- `DEPLOY_SECRET_KEY` - приватный SSH ключ для доступа к серверу

## 5. Настройка переменных окружения

### 5.1. Admin Panel (api-project-marketplace)

В `docker-compose.yml` проверьте переменные окружения для admin-panel:
- `PORT=8080` - порт для admin-panel
- База данных: `postgres-admin` (отдельная БД `admin_panel_db`)

### 5.2. Backend

В `docker-compose.yml` проверьте переменные окружения для backend:
- `SERVER_PORT=8081` - порт для backend (⚠️ отличается от admin-panel!)
- `DB_HOST=postgres-backend`
- `DB_PORT=5432`
- `DB_USER=postgres`
- `DB_PASSWORD=postgres` (⚠️ измените на безопасный пароль!)
- `DB_NAME=backend_db` (отдельная БД для backend)

### 5.3. Frontend

В `docker-compose.yml` проверьте переменные окружения для frontend:
- `VITE_API_BASE_URL=https://erp.lifedream.tech/api` (⚠️ поддомен erp!)

## 6. Настройка Nginx

### 6.1. Проверка конфигурации

Убедитесь, что файлы nginx содержат правильные настройки:

**`nginx/conf.d/lifedream.tech.conf`** - основной домен (admin-panel):
- Правильные пути к SSL сертификатам
- Проксирование на `admin-panel:8080`
- Только для домена `lifedream.tech`

**`nginx/conf.d/erp.lifedream.tech.conf`** - поддомен (backend + frontend):
- Правильные пути к SSL сертификатам
- Проксирование на `backend:8081` для `/api/`
- Проксирование на `frontend:80` для `/`
- Только для домена `erp.lifedream.tech`

**Важно:** Убедитесь, что DNS настроен для поддомена `erp.lifedream.tech`

### 6.2. Логи Nginx

Директория для логов создается автоматически, но убедитесь что она существует:
```bash
mkdir -p nginx/logs
```

## 7. Первый деплой

### 7.1. Клонирование репозитория инфраструктуры на сервер

```bash
cd /root/project
git clone git@github.com:YOUR_USERNAME/deployment-repo.git deployment
cd deployment
```

**Важно:** Репозиторий инфраструктуры клонируется в папку `deployment`, а не `api-project-marketplace`!

### 7.2. Размещение SSL сертификатов

```bash
# Скопируйте сертификаты в nginx/ssl/
cp /path/to/lifedream.tech.crt nginx/ssl/
cp /path/to/lifedream.tech.key nginx/ssl/
```

### 7.3. Запуск первого деплоя

```bash
# Настройка репозиториев
bash scripts/setup-repositories.sh

# Запуск контейнеров
docker-compose up -d --build
```

## 8. Проверка после деплоя

### 8.1. Проверка контейнеров

```bash
docker-compose ps
```

Все сервисы должны быть в статусе `Up`.

### 8.2. Проверка логов

```bash
docker-compose logs nginx
docker-compose logs admin-panel
docker-compose logs backend
docker-compose logs frontend
```

### 8.3. Проверка доступности

**Основной домен (lifedream.tech):**
- Admin Panel API: `https://lifedream.tech/api/`
- Admin Panel WebSocket: `https://lifedream.tech/api/ws`

**Поддомен ERP (erp.lifedream.tech):**
- Frontend: `https://erp.lifedream.tech`
- Backend API: `https://erp.lifedream.tech/api/`

## 9. Автоматический деплой

### 9.1. Деплой инфраструктуры

После настройки всех вышеперечисленных пунктов, автоматический деплой будет работать при пуше в ветку `master` или `main` репозитория инфраструктуры.

Workflow файл: `.github/workflows/deploy.yml`

При обновлении репозитория `deployment`:
1. Обновляется сам репозиторий deployment
2. Обновляются все репозитории (api-project-marketplace, backend, frontend)
3. Перезапускаются все контейнеры

### 9.2. Деплой отдельных репозиториев

**⚠️ ВАЖНО:** Без настройки CI/CD в каждом репозитории, изменения в `backend`, `frontend` или `admin-panel-golang` не будут автоматически деплоиться на сервер!

**Настройка автоматического деплоя для каждого репозитория:**

1. **Backend репозиторий:**
   - Скопируйте `.github/workflows/deploy-backend.yml.example` из `deployment` в `backend/.github/workflows/deploy.yml`
   - Настройте GitHub Secrets в репозитории `backend`
   - При пуше в `main`/`master` будет обновляться только backend

2. **Frontend репозиторий:**
   - Скопируйте `.github/workflows/deploy-frontend.yml.example` из `deployment` в `frontend/.github/workflows/deploy.yml`
   - Настройте GitHub Secrets в репозитории `frontend`
   - При пуше в `main`/`master` будет обновляться только frontend

3. **Admin Panel репозиторий (api-project-marketplace):**
   - Скопируйте `.github/workflows/deploy-admin-panel.yml.example` из `deployment` в `admin-panel-golang/.github/workflows/deploy.yml`
   - Настройте GitHub Secrets в репозитории `admin-panel-golang`
   - При пуше в `main`/`master` будет обновляться только admin-panel

**Как это работает:**
- Каждый workflow использует скрипт `update-single-repo.sh` для обновления конкретного репозитория
- Перезапускаются только соответствующие контейнеры (не все)
- Это позволяет деплоить изменения быстрее и без влияния на другие сервисы

**Примеры workflows находятся в:**
- `deployment/.github/workflows/deploy-backend.yml.example`
- `deployment/.github/workflows/deploy-frontend.yml.example`
- `deployment/.github/workflows/deploy-admin-panel.yml.example`

## 10. Дополнительные настройки (опционально)

### 10.1. Автоматическое обновление отдельных репозиториев

Если нужно настроить автоматический деплой при обновлении конкретного репозитория (например, backend), можно добавить GitHub Actions workflow в этот репозиторий, который будет триггерить обновление инфраструктуры.

### 10.2. Мониторинг и логирование

Рекомендуется настроить:
- Мониторинг контейнеров (например, через Docker healthchecks)
- Централизованное логирование
- Алерты при падении сервисов

### 10.3. Резервное копирование

Настройте регулярное резервное копирование:
- База данных PostgreSQL
- Конфигурационные файлы
- SSL сертификаты

## 11. Частые проблемы

### Проблема: Репозитории не клонируются

**Решение:**
- Проверьте SSH ключ: `ssh -T git@github.com`
- Убедитесь, что ключ добавлен в ssh-agent: `ssh-add ~/.ssh/github_keys`

### Проблема: Nginx не запускается

**Решение:**
- Проверьте наличие SSL сертификатов
- Проверьте синтаксис конфигурации: `nginx -t`
- Проверьте логи: `docker-compose logs nginx`

### Проблема: Контейнеры не могут подключиться друг к другу

**Решение:**
- Убедитесь, что все сервисы в одной сети (`app-network`)
- Проверьте имена сервисов в docker-compose.yml
- Проверьте, что сервисы запущены: `docker-compose ps`

## Важные замечания

⚠️ **Безопасность:**
- Никогда не коммитьте SSL сертификаты в git
- Используйте сильные пароли для базы данных
- Ограничьте доступ к серверу по SSH (используйте ключи, отключите парольную аутентификацию)

⚠️ **Производительность:**
- Настройте лимиты ресурсов для контейнеров в docker-compose.yml
- Используйте production-ready настройки для Nginx
- Настройте кэширование статических файлов
