# Быстрый старт для deployment

Этот документ описывает быстрый способ настроить deployment для работы с api-project-marketplace.

## Предварительные требования

1. На сервере должен существовать репозиторий api-project-marketplace:
   - `/root/project/api-project-marketplace/` (предпочтительно)
   - или `/root/project/api-admin-marketplace/` (старое имя)

2. Настроен SSH доступ к серверу
3. Установлены Docker и Docker Compose

## Шаги настройки

### 1. Клонирование deployment репозитория

```bash
cd /root/project
git clone <your-deployment-repo-url> deployment
cd deployment
```

### 2. Проверка имени папки проекта

```bash
# Проверьте, какое имя у папки проекта
ls -la ../ | grep -E "api-project-marketplace|api-admin-marketplace"

# Если папка называется api-admin-marketplace, можно:
# Вариант 1: Переименовать (рекомендуется)
mv ../api-admin-marketplace ../api-project-marketplace

# Вариант 2: Создать симлинк
ln -s ../api-admin-marketplace ../api-project-marketplace
```

### 3. Размещение SSL сертификатов

```bash
# Создайте директорию для SSL
mkdir -p nginx/ssl

# Скопируйте сертификаты
cp /path/to/lifedream.tech.crt nginx/ssl/
cp /path/to/lifedream.tech.key nginx/ssl/
```

### 4. Первый запуск

```bash
# Запустите контейнеры
docker-compose up -d --build

# Проверьте статус
docker-compose ps

# Проверьте логи
docker-compose logs -f
```

### 5. Проверка работы

```bash
# Проверьте доступность сайта
curl -I https://lifedream.tech

# Проверьте API
curl -I https://lifedream.tech/api/
```

## Настройка GitHub Actions

### 1. В репозитории deployment

Настройте GitHub Secrets:
- `SERVER_HOST` - IP или домен сервера
- `SERVER_USER` - пользователь SSH (обычно `root`)
- `DEPLOY_SECRET_KEY` - приватный SSH ключ

### 2. В репозитории admin-panel-golang

Workflow уже обновлен и будет использовать deployment для запуска контейнеров.

Настройте GitHub Secrets (те же, что и для deployment):
- `SERVER_HOST`
- `SERVER_USER`
- `DEPLOY_SECRET_KEY`

## Как это работает

### При изменении в admin-panel-golang:

1. GitHub Actions workflow запускается
2. Подключается к серверу
3. Обновляет репозиторий api-project-marketplace
4. Перезапускает контейнеры через deployment

### При изменении в deployment:

1. GitHub Actions workflow запускается
2. Подключается к серверу
3. Обновляет репозиторий deployment
4. Обновляет api-project-marketplace
5. Перезапускает все контейнеры

## Отладка

### Проблема: Репозиторий не найден

```bash
# Проверьте путь
cd /root/project
ls -la | grep api

# Убедитесь, что папка называется правильно
# Скрипт ищет: api-project-marketplace или api-admin-marketplace
```

### Проблема: Контейнеры не запускаются

```bash
# Проверьте логи
cd /root/project/deployment
docker-compose logs

# Проверьте конфигурацию
docker-compose config
```

### Проблема: Nginx не может найти SSL сертификаты

```bash
# Проверьте наличие сертификатов
ls -la nginx/ssl/

# Должны быть:
# - lifedream.tech.crt
# - lifedream.tech.key
```

## Следующие шаги

После успешной настройки deployment для api-project-marketplace, можно добавить:
- Backend репозиторий
- Frontend репозиторий

См. [DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md) для полной настройки.
