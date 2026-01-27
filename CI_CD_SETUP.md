# Настройка CI/CD для автоматического деплоя

Этот документ описывает, как настроить автоматический деплой для каждого репозитория.

## Проблема

По умолчанию, при изменении в репозиториях `backend`, `frontend` или `admin-panel-golang` ничего не происходит на сервере автоматически. Обновление происходит только при изменении репозитория `deployment`.

## Решение

Нужно настроить GitHub Actions workflow в каждом репозитории, который будет автоматически деплоить изменения на сервер.

## Структура деплоя

### 1. Деплой инфраструктуры (deployment)

**Триггер:** Пуш в `master`/`main` репозитория `deployment`

**Что происходит:**
- Обновляются все репозитории (api-project-marketplace, backend, frontend)
- Перезапускаются все контейнеры

**Workflow:** `.github/workflows/deploy.yml` (уже настроен)

### 2. Деплой отдельных репозиториев

**Триггер:** Пуш в `master`/`main` конкретного репозитория

**Что происходит:**
- Обновляется только этот репозиторий
- Перезапускаются только соответствующие контейнеры

## Настройка для каждого репозитория

### Backend

1. **Создайте workflow файл:**
   ```bash
   # В репозитории backend
   mkdir -p .github/workflows
   cp /path/to/deployment/.github/workflows/deploy-backend.yml.example .github/workflows/deploy.yml
   ```

2. **Настройте GitHub Secrets в репозитории `backend`:**
   - Settings → Secrets and variables → Actions
   - Добавьте:
     - `SERVER_HOST` - IP или домен сервера
     - `SERVER_USER` - пользователь SSH (обычно `root`)
     - `DEPLOY_SECRET_KEY` - приватный SSH ключ для доступа к серверу

3. **Проверьте настройки:**
   - Убедитесь, что в `deployment/scripts/update-single-repo.sh` правильно указан путь к репозиторию backend

### Frontend

1. **Создайте workflow файл:**
   ```bash
   # В репозитории frontend
   mkdir -p .github/workflows
   cp /path/to/deployment/.github/workflows/deploy-frontend.yml.example .github/workflows/deploy.yml
   ```

2. **Настройте GitHub Secrets** (аналогично backend)

3. **Проверьте настройки** в `update-single-repo.sh`

### Admin Panel (api-project-marketplace)

1. **Создайте workflow файл:**
   ```bash
   # В репозитории admin-panel-golang
   mkdir -p .github/workflows
   cp /path/to/deployment/.github/workflows/deploy-admin-panel.yml.example .github/workflows/deploy.yml
   ```

2. **Настройте GitHub Secrets** (аналогично backend)

3. **Проверьте настройки** в `update-single-repo.sh`

## Как работают workflows

### Backend workflow

```yaml
# При пуше в main/master:
1. Подключается к серверу по SSH
2. Переходит в /root/project/deployment
3. Запускает: bash scripts/update-single-repo.sh backend
4. Перезапускает: docker-compose up -d --build backend postgres-backend
```

### Frontend workflow

```yaml
# При пуше в main/master:
1. Подключается к серверу по SSH
2. Переходит в /root/project/deployment
3. Запускает: bash scripts/update-single-repo.sh frontend
4. Перезапускает: docker-compose up -d --build frontend
```

### Admin Panel workflow

```yaml
# При пуше в main/master:
1. Подключается к серверу по SSH
2. Переходит в /root/project/deployment
3. Запускает: bash scripts/update-single-repo.sh api-project-marketplace
4. Перезапускает: docker-compose up -d --build admin-panel postgres-admin
```

## Преимущества

✅ **Быстрый деплой** - обновляется только измененный сервис
✅ **Независимость** - изменения в одном репозитории не влияют на другие
✅ **Экономия ресурсов** - не пересобираются все контейнеры
✅ **Гибкость** - можно деплоить каждый сервис отдельно

## Проверка работы

После настройки:

1. Сделайте небольшое изменение в `backend`
2. Закоммитьте и запушьте в `main`
3. Проверьте Actions в GitHub - должен запуститься workflow
4. Проверьте логи на сервере - должен обновиться только backend

## Troubleshooting

### Проблема: Workflow не запускается

**Решение:**
- Проверьте, что файл находится в `.github/workflows/deploy.yml`
- Проверьте, что ветка называется `main` или `master` (как указано в workflow)
- Проверьте, что файл имеет правильный синтаксис YAML

### Проблема: Ошибка SSH подключения

**Решение:**
- Проверьте GitHub Secrets (SERVER_HOST, SERVER_USER, DEPLOY_SECRET_KEY)
- Убедитесь, что SSH ключ правильный и добавлен на сервер
- Проверьте, что сервер доступен из интернета

### Проблема: Репозиторий не обновляется

**Решение:**
- Проверьте настройки в `update-single-repo.sh`
- Убедитесь, что SSH ключ настроен на сервере (`~/.ssh/github_keys`)
- Проверьте, что репозиторий существует на сервере в правильной папке

## Альтернативный подход (без CI/CD)

Если не хотите настраивать CI/CD для каждого репозитория, можно:

1. Обновлять репозитории вручную на сервере
2. Использовать только деплой через `deployment` репозиторий
3. Настроить webhook, который будет триггерить обновление при пуше

Но это менее удобно и требует ручного вмешательства.
