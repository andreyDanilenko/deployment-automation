# Руководство по безопасному переносу деплоя

Этот документ описывает, как безопасно перенести деплой из `api-project-marketplace` в `deployment`.

## Текущая ситуация

**Старый способ (api-project-marketplace):**
- Репозиторий: `/root/project/api-admin-marketplace` (или `/root/project/api-project-marketplace`)
- Docker Compose находится внутри репозитория
- При пуше в `master` обновляется репозиторий и перезапускаются контейнеры

**Новый способ (deployment):**
- Репозиторий инфраструктуры: `/root/project/deployment`
- Репозиторий проекта: `/root/project/api-project-marketplace`
- Docker Compose находится в `deployment`
- При пуше в `master` обновляется проект и перезапускаются контейнеры через deployment

## План безопасного переноса

### Этап 1: Подготовка (без простоя)

1. **Клонируйте репозиторий deployment на сервер:**
   ```bash
   cd /root/project
   git clone <your-deployment-repo> deployment
   cd deployment
   ```

2. **Проверьте структуру:**
   ```bash
   # Убедитесь, что api-project-marketplace существует
   ls -la ../api-project-marketplace
   # или
   ls -la ../api-admin-marketplace
   ```

3. **Настройте SSL сертификаты:**
   ```bash
   # Скопируйте сертификаты в deployment
   cp /path/to/lifedream.tech.crt nginx/ssl/
   cp /path/to/lifedream.tech.key nginx/ssl/
   ```

4. **Проверьте конфигурацию docker-compose:**
   ```bash
   # Проверьте, что пути правильные
   cat docker-compose.yml
   # Должно быть: context: ../api-project-marketplace/app
   ```

### Этап 2: Тестовый запуск (с откатом)

1. **Остановите старые контейнеры (если они запущены из api-project-marketplace):**
   ```bash
   cd /root/project/api-project-marketplace
   # или cd /root/project/api-admin-marketplace
   docker-compose down
   ```

2. **Запустите новые контейнеры из deployment:**
   ```bash
   cd /root/project/deployment
   docker-compose up -d --build
   ```

3. **Проверьте работу:**
   ```bash
   # Проверьте статус контейнеров
   docker-compose ps
   
   # Проверьте логи
   docker-compose logs nginx
   docker-compose logs admin-panel
   
   # Проверьте доступность
   curl -I https://lifedream.tech
   ```

4. **Если что-то не работает - откат:**
   ```bash
   cd /root/project/deployment
   docker-compose down
   
   cd /root/project/api-project-marketplace
   # или cd /root/project/api-admin-marketplace
   docker-compose up -d
   ```

### Этап 3: Обновление workflows

1. **Обновите workflow в admin-panel-golang:**
   - Файл уже обновлен в репозитории
   - Он теперь использует deployment для запуска контейнеров

2. **Проверьте GitHub Secrets:**
   - Убедитесь, что в репозитории `admin-panel-golang` настроены:
     - `SERVER_HOST`
     - `SERVER_USER`
     - `DEPLOY_SECRET_KEY`

3. **Протестируйте автоматический деплой:**
   - Сделайте небольшое изменение в `admin-panel-golang`
   - Закоммитьте и запушьте в `master`
   - Проверьте, что workflow запустился и контейнеры обновились

### Этап 4: Финальная настройка

1. **Убедитесь, что старый docker-compose больше не используется:**
   ```bash
   # Проверьте, нет ли запущенных контейнеров из старого места
   docker ps | grep admin-panel
   ```

2. **Обновите документацию:**
   - Убедитесь, что все инструкции указывают на deployment

3. **Мониторинг:**
   - Следите за логами первые несколько дней
   - Убедитесь, что деплои проходят успешно

## Важные моменты

### Имена папок

На сервере может быть:
- `/root/project/api-project-marketplace` (новое имя)
- `/root/project/api-admin-marketplace` (старое имя)

**Проверьте и обновите:**
- `docker-compose.yml` - путь должен быть правильным
- `scripts/update-api-project.sh` - путь должен быть правильным

### Порты

Убедитесь, что:
- Nginx слушает на портах 80 и 443
- Admin-panel слушает на порту 8080 (внутри контейнера)
- Нет конфликтов портов

### База данных

При переносе:
- Данные БД сохраняются в Docker volume `postgres_admin_data`
- Если используете старый docker-compose, нужно перенести volume

**Перенос volume (если нужно):**
```bash
# Остановите старые контейнеры
cd /root/project/api-project-marketplace
docker-compose down

# Найдите volume
docker volume ls | grep postgres

# Создайте backup (опционально)
docker run --rm -v old_volume:/data -v $(pwd):/backup alpine tar czf /backup/backup.tar.gz /data

# Новый docker-compose создаст новый volume автоматически
# Или можно указать существующий volume в docker-compose.yml
```

## Проверочный список

- [ ] Репозиторий deployment клонирован на сервер
- [ ] SSL сертификаты размещены в `deployment/nginx/ssl/`
- [ ] Путь к api-project-marketplace правильный в docker-compose.yml
- [ ] Контейнеры запускаются из deployment
- [ ] Сайт доступен по https://lifedream.tech
- [ ] API работает по https://lifedream.tech/api/
- [ ] Workflow в admin-panel-golang обновлен
- [ ] GitHub Secrets настроены
- [ ] Автоматический деплой работает
- [ ] Старые контейнеры остановлены

## Откат

Если что-то пошло не так:

1. **Остановите новые контейнеры:**
   ```bash
   cd /root/project/deployment
   docker-compose down
   ```

2. **Запустите старые контейнеры:**
   ```bash
   cd /root/project/api-project-marketplace
   # или
   cd /root/project/api-admin-marketplace
   docker-compose up -d
   ```

3. **Откатите изменения в workflow:**
   - Верните старую версию `.github/workflows/deploy.yml` в admin-panel-golang

4. **Исправьте проблемы и повторите попытку**

## После успешного переноса

1. Можно удалить старый docker-compose.yml из api-project-marketplace (опционально)
2. Обновите документацию
3. Сообщите команде о новой структуре деплоя
