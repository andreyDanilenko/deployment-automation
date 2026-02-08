# Мини-гайд по Nginx в проекте

## Роли конфигов

| Файл | Назначение |
|------|------------|
| `nginx/nginx.conf` | Прод: домены lifedream.tech и habits.lifedream.tech, HTTPS (порты 80/443). |
| `nginx/nginx.dev.conf` | Разработка: один хост localhost, HTTP на порту 80 (с хоста — 8080). |

В проде используется `nginx.conf`, в dev-композе подставляется `nginx.dev.conf` через volume.

## Что делает Nginx

- **Reverse proxy** — принимает запросы снаружи и отдаёт их бэкендам (article_app, habits_api, habits_frontend) по внутренним именам контейнеров.
- **Маршрутизация по `location`** — выбор бэкенда по пути запроса (например `/api/` → article_app, `/habits-api/` → habits_api в dev).
- **SSL** — только в проде (сертификаты в `nginx/ssl/`).

## SSL и поддомены (habits.lifedream.tech)

- Сертификат `lifedream.tech.crt` обычно покрывает только **lifedream.tech** и **www.lifedream.tech**. Для **habits.lifedream.tech** он не подходит — браузер покажет ошибку сертификата.
- Решения:
  1. **Wildcard-сертификат** `*.lifedream.tech` — один сертификат для всех поддоменов; указать его в `ssl_certificate` для всех блоков 443.
  2. **Отдельный сертификат** для habits — положить в `nginx/ssl/` (например `habits.lifedream.tech.crt` и `.key`) и в блоке `server_name habits.lifedream.tech` указать эти файлы.
- На сервере папка `deployment/nginx/ssl/` не в git (в `.gitignore`). После клона репозитория нужно **скопировать** сертификаты в эту папку (например из `admin-panel-golang/nginx/ssl/` или с места выпуска). Иначе nginx не найдёт файлы и не запустится на 443.

## Полезные ссылки (официальная документация)

- **Главная документация:** https://nginx.org/en/docs/
- **Директива `server`:** https://nginx.org/en/docs/http/ngx_http_core_module.html#server
- **Директива `location`:** https://nginx.org/en/docs/http/ngx_http_core_module.html#location
- **Проксирование (`proxy_pass` и др.):** https://nginx.org/en/docs/http/ngx_http_proxy_module.html
- **Reverse proxy (обзор):** https://docs.nginx.com/nginx-admin-guide/web-server/reverse-proxy/
- **Upstream (бэкенды):** https://nginx.org/en/docs/http/ngx_http_upstream_module.html
- **SSL (ssl_certificate и др.):** https://nginx.org/en/docs/http/ngx_http_ssl_module.html

## Порты и конфликты

- **Прод (`docker-compose.yml`):** только контейнер `nginx` публикует порты `80` и `443`. Остальные сервисы только `expose` (доступны только внутри сети Docker).
- **Разработка (`docker-compose.dev.yml`):** nginx публикует только `8080:80`. Порты 80 и 443 на хосте свободны, конфликта с продом нет.

После правок конфига перезапуск nginx в композе:
`docker compose -f docker-compose.dev.yml restart nginx` (или пересборка/подъём стека).
