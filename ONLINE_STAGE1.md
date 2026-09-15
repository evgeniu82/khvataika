# Хватайка 2.0.0 — Online Stage 1

Stage 1 подключает только безопасный фоновой сетевой слой:

- `/api/game/ping` — проверка доступности сервера;
- `/api/player/register` — создание/обновление серверной сессии игрока;
- timeout 3 секунды;
- повторные попытки с backoff;
- запросы не участвуют в игровом цикле;
- сервер не меняет локальный игровой результат и не блокирует игру.

## Настройки

В `project.godot`:

- `application/config/online_stage1_enabled=true`
- `application/config/online_stage1_server_url="http://135.106.209.40:8080"`
- `application/config/online_stage1_timeout=3.0`

Для релиза серверный URL должен использовать HTTPS.

## Что намеренно НЕ включено

Stage 1 не включает server-authoritative gameplay, покупки, экономику, удалённую замену сохранения, remote catalog/config и ожидание сервера перед игрой. Это следующие этапы.
