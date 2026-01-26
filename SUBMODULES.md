# Работа с Git Submodules и уникальными названиями репозиториев

## Важно понимать

**Название репозитория** и **название папки submodule** - это разные вещи!

## Пример

### Репозитории с уникальными названиями

- Репозиторий: `https://github.com/your-org/my-awesome-frontend-app.git`
- Репозиторий: `https://github.com/your-org/super-backend-api.git`

### Добавление как Submodules

Вы можете выбрать **любое название папки** при добавлении submodule:

```bash
# Вариант 1: Использовать короткое название (рекомендуется)
git submodule add https://github.com/your-org/my-awesome-frontend-app.git projects/frontend
git submodule add https://github.com/your-org/super-backend-api.git projects/backend

# Вариант 2: Использовать название репозитория
git submodule add https://github.com/your-org/my-awesome-frontend-app.git projects/my-awesome-frontend-app
git submodule add https://github.com/your-org/super-backend-api.git projects/super-backend-api

# Вариант 3: Использовать свое название
git submodule add https://github.com/your-org/my-awesome-frontend-app.git projects/app-ui
git submodule add https://github.com/your-org/super-backend-api.git projects/api-server
```

### В docker-compose.yml

В `context:` указывается **путь к папке**, которую вы указали при `git submodule add`:

**Если использовали вариант 1:**
```yaml
frontend:
  build:
    context: ./projects/frontend  # Название папки, не репозитория!
    dockerfile: Dockerfile
```

**Если использовали вариант 2:**
```yaml
frontend:
  build:
    context: ./projects/my-awesome-frontend-app  # Название папки = название репозитория
    dockerfile: Dockerfile
```

**Если использовали вариант 3:**
```yaml
frontend:
  build:
    context: ./projects/app-ui  # Ваше название папки
    dockerfile: Dockerfile
```

## Рекомендации

### ✅ Рекомендуется: Короткие названия папок

```bash
# Репозитории могут иметь длинные названия
git submodule add https://github.com/your-org/my-awesome-frontend-app.git projects/frontend
git submodule add https://github.com/your-org/super-backend-api.git projects/backend
```

**Преимущества:**
- Короткие пути в docker-compose.yml
- Легче читать конфигурацию
- Не зависит от названия репозитория

### ⚠️ Альтернатива: Использовать название репозитория

```bash
git submodule add https://github.com/your-org/my-awesome-frontend-app.git projects/my-awesome-frontend-app
```

**Когда использовать:**
- Если у вас много проектов и нужно явно видеть, какой репозиторий
- Если названия репозиториев уже короткие и понятные

## Полный пример

### Репозитории:
- `https://github.com/company/project-alpha-frontend.git`
- `https://github.com/company/project-alpha-backend.git`

### Добавление submodules:

```bash
cd deployment

# Добавляем с короткими названиями папок
git submodule add https://github.com/company/project-alpha-frontend.git projects/frontend
git submodule add https://github.com/company/project-alpha-backend.git projects/backend

git submodule update --init --recursive
```

### Структура:

```
deployment/
├── projects/
│   ├── frontend/      # Репозиторий project-alpha-frontend, но папка называется frontend
│   └── backend/       # Репозиторий project-alpha-backend, но папка называется backend
└── docker-compose.yml
```

### docker-compose.yml:

```yaml
services:
  frontend:
    build:
      context: ./projects/frontend  # Путь к папке, не к репозиторию!
      dockerfile: Dockerfile

  backend:
    build:
      context: ./projects/backend  # Путь к папке, не к репозиторию!
      dockerfile: Dockerfile
```

## Если репозиторий содержит frontend и backend

Если у вас один репозиторий с frontend и backend:

```
my-project-repo/
├── frontend/
│   └── Dockerfile
└── backend/
    └── Dockerfile
```

### Добавление:

```bash
git submodule add https://github.com/company/my-project-repo.git projects/my-project
```

### docker-compose.yml:

```yaml
services:
  frontend:
    build:
      context: ./projects/my-project/frontend  # Путь к подпапке
      dockerfile: Dockerfile

  backend:
    build:
      context: ./projects/my-project/backend  # Путь к подпапке
      dockerfile: Dockerfile
```

## Резюме

1. **Название репозитория** может быть любым (`my-awesome-frontend-app`)
2. **Название папки submodule** задается вами при `git submodule add <URL> <path>`
3. **В docker-compose.yml** указывается путь к папке submodule, не к репозиторию
4. **Рекомендуется** использовать короткие названия папок для удобства

## Примеры разных сценариев

### Сценарий 1: Один репозиторий = один сервис

```bash
# Репозиторий: company-frontend-v2
git submodule add https://github.com/company/company-frontend-v2.git projects/frontend
```

```yaml
context: ./projects/frontend
```

### Сценарий 2: Один репозиторий = несколько сервисов

```bash
# Репозиторий: fullstack-app
git submodule add https://github.com/company/fullstack-app.git projects/fullstack-app
```

```yaml
frontend:
  build:
    context: ./projects/fullstack-app/frontend

backend:
  build:
    context: ./projects/fullstack-app/backend
```

### Сценарий 3: Несколько проектов

```bash
git submodule add https://github.com/company/project1-frontend.git projects/project1-frontend
git submodule add https://github.com/company/project2-ui.git projects/project2-ui
```

```yaml
project1-frontend:
  build:
    context: ./projects/project1-frontend

project2-ui:
  build:
    context: ./projects/project2-ui
```


