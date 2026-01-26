# Миграция на Git Submodules

## Текущая структура (без Submodules)

```
myProject/
├── frontend/          # Обычная папка или отдельный репозиторий
├── backend/           # Обычная папка или отдельный репозиторий
└── deployment/
    └── docker-compose.yml  # context: ../frontend
```

В `docker-compose.yml`:
```yaml
frontend:
  build:
    context: ../frontend  # Путь к соседней папке
    dockerfile: Dockerfile
```

## Структура с Git Submodules

### Шаг 1: Добавить проекты как Submodules

```bash
cd deployment

# URL репозитория указывается ЗДЕСЬ
git submodule add https://github.com/your-org/frontend.git projects/frontend
git submodule add https://github.com/your-org/backend.git projects/backend

# Инициализировать
git submodule update --init --recursive
```

Результат:
```
deployment/
├── projects/
│   ├── frontend/      # Git Submodule (склонированный репозиторий)
│   └── backend/       # Git Submodule (склонированный репозиторий)
└── docker-compose.yml
```

### Шаг 2: Обновить docker-compose.yml

```yaml
frontend:
  build:
    context: ./projects/frontend  # Путь к папке submodule, НЕ URL!
    dockerfile: Dockerfile
```

## Важно понимать

### ❌ НЕПРАВИЛЬНО

```yaml
frontend:
  build:
    context: https://github.com/your-org/frontend.git  # ❌ Это не путь!
    dockerfile: Dockerfile
```

### ✅ ПРАВИЛЬНО

**Вариант 1: Соседние папки (текущая структура)**
```yaml
frontend:
  build:
    context: ../frontend  # ✅ Путь к папке
    dockerfile: Dockerfile
```

**Вариант 2: Git Submodules**
```yaml
frontend:
  build:
    context: ./projects/frontend  # ✅ Путь к папке submodule
    dockerfile: Dockerfile
```

## Полный пример миграции

### 1. Исходное состояние

```yaml
# docker-compose.yml
frontend:
  build:
    context: ../frontend
```

### 2. Добавить submodule

```bash
cd deployment
git submodule add https://github.com/your-org/frontend.git projects/frontend
git submodule update --init --recursive
```

### 3. Обновить docker-compose.yml

```yaml
# docker-compose.yml
frontend:
  build:
    context: ./projects/frontend  # Изменили путь
    dockerfile: Dockerfile
```

### 4. Проверить

```bash
docker-compose config  # Проверить конфигурацию
docker-compose build   # Собрать образ
```

## Резюме

- **URL репозитория** → указывается в команде `git submodule add <URL> <path>`
- **context в docker-compose.yml** → указывается путь к папке на диске (куда submodule был склонирован)

Они связаны так:
```
git submodule add <URL> projects/frontend
                                    ↓
                          создается папка projects/frontend
                                    ↓
context: ./projects/frontend  ← указываем путь к этой папке
```


