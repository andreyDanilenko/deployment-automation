# Инструкция по настройке Deployment

Пошаговая инструкция по настройке репозитория-конфига для развертывания нескольких проектов.

## Сценарий 1: Новый репозиторий-конфиг с Git Submodules

### Шаг 1: Создать репозиторий-конфиг

```bash
mkdir deployment
cd deployment
git init
```

### Шаг 2: Добавить базовые файлы

Скопируйте в репозиторий:
- `docker-compose.yml`
- `nginx/`
- `.env.example`
- `.gitignore`

### Шаг 3: Добавить проекты как Submodules

```bash
# Добавить проект 1
git submodule add <URL-репозитория-проекта-1> projects/project1

# Добавить проект 2
git submodule add <URL-репозитория-проекта-2> projects/project2

# Инициализировать
git submodule update --init --recursive
```

### Шаг 4: Настроить docker-compose.yml

Отредактируйте `docker-compose.yml` для ссылки на проекты:

```yaml
services:
  project1-frontend:
    build:
      context: ./projects/project1/frontend
      dockerfile: Dockerfile
```

### Шаг 5: Настроить Nginx

```bash
cp nginx/conf.d/template.conf.example nginx/conf.d/project1.conf
# Отредактируйте project1.conf
```

### Шаг 6: Запустить

```bash
docker-compose up -d
```

## Сценарий 2: Текущая структура (проекты в соседних папках)

Если у вас уже есть структура:
```
myProject/
├── frontend/
├── backend/
└── deployment/
```

### Вариант A: Оставить как есть

Текущий `docker-compose.yml` уже настроен на `../frontend` и `../backend`.

### Вариант B: Мигрировать на Submodules

1. **Создать Git репозитории** для frontend и backend (если еще не созданы)

2. **Добавить как submodules:**

```bash
cd deployment

# Если проекты уже в отдельных репозиториях
git submodule add <URL-frontend-repo> projects/frontend
git submodule add <URL-backend-repo> projects/backend

# Обновить docker-compose.yml:
# context: ./projects/frontend
# context: ./projects/backend
```

3. **Обновить docker-compose.yml**

## Сценарий 3: Добавление нового проекта

### Шаг 1: Добавить проект как Submodule

```bash
cd deployment
git submodule add <URL-нового-проекта> projects/new-project
git submodule update --init --recursive
```

### Шаг 2: Добавить в docker-compose.yml

```yaml
services:
  new-project-frontend:
    build:
      context: ./projects/new-project/frontend
      dockerfile: Dockerfile
    container_name: new-project-frontend
    networks:
      - app-network
```

### Шаг 3: Создать Nginx конфигурацию

```bash
cp nginx/conf.d/template.conf.example nginx/conf.d/new-project.conf
# Настроить server_name и proxy_pass
```

### Шаг 4: Обновить зависимости Nginx

```yaml
nginx:
  depends_on:
    - new-project-frontend
    - new-project-backend
```

### Шаг 5: Запустить

```bash
docker-compose up -d --build
```

## Работа с Git Submodules

### Клонирование репозитория-конфига

```bash
# С submodules сразу
git clone --recursive <URL-репозитория-конфига>

# Или после клонирования
git clone <URL-репозитория-конфига>
cd deployment
git submodule update --init --recursive
```

### Обновление проектов

```bash
# Обновить все submodules до последних коммитов
git submodule update --remote

# Обновить конкретный проект
git submodule update --remote projects/project1
```

### Фиксация версий проектов

```bash
# Перейти в директорию проекта
cd projects/project1
git checkout v1.0.0

# Вернуться и закоммитить
cd ../..
git add projects/project1
git commit -m "Pin project1 to v1.0.0"
```

## Структура проектов

Убедитесь, что каждый проект имеет Dockerfile:

### Вариант 1: Отдельные frontend/backend

```
project/
├── frontend/
│   ├── Dockerfile
│   └── ...
└── backend/
    ├── Dockerfile
    └── ...
```

В docker-compose.yml:
```yaml
build:
  context: ./projects/project/frontend
  dockerfile: Dockerfile
```

### Вариант 2: Монолитный проект

```
project/
├── Dockerfile
└── ...
```

В docker-compose.yml:
```yaml
build:
  context: ./projects/project
  dockerfile: Dockerfile
```

## Проверка настройки

### 1. Проверить структуру

```bash
tree -L 3 projects/
```

### 2. Проверить docker-compose

```bash
docker-compose config
```

### 3. Проверить Nginx конфигурацию

```bash
docker-compose exec nginx nginx -t
```

### 4. Проверить статус сервисов

```bash
docker-compose ps
```

## Troubleshooting

### Submodule показывает как измененный

```bash
# Это нормально, если вы обновили submodule
git submodule status

# Если хотите зафиксировать версию
git add projects/project1
git commit -m "Update project1"
```

### Docker не находит Dockerfile

Проверьте пути в `docker-compose.yml`:
- Пути должны быть относительно `docker-compose.yml`
- Используйте `./projects/project/frontend`, а не абсолютные пути

### Nginx не видит новые сервисы

1. Проверьте, что сервисы запущены: `docker-compose ps`
2. Проверьте конфигурацию Nginx: `docker-compose exec nginx nginx -t`
3. Перезагрузите Nginx: `docker-compose restart nginx`

## Полезные скрипты

### init-submodules.sh

```bash
chmod +x scripts/init-submodules.sh
./scripts/init-submodules.sh
```

### Обновление всех проектов

```bash
#!/bin/bash
# update-all-projects.sh
git submodule update --remote
docker-compose build
docker-compose up -d
```

## Best Practices

1. **Версионирование**: Фиксируйте версии проектов через коммиты в submodules
2. **Изоляция**: Каждый проект независим
3. **Документация**: Документируйте структуру каждого проекта
4. **Тестирование**: Тестируйте изменения в dev окружении
5. **Резервное копирование**: Регулярно делайте бэкапы БД


