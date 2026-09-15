# Хватайка — authoritative server v2

Сервер является источником истины для авторитетных онлайн-операций: аккаунтов, экономики, инвентаря, наград, рейтинга, миссий, сезона, событий, промокодов и покупок.

Локальный gameplay не блокируется сервером. При отсутствии подтверждённой серверной сессии игра продолжает работать локально.

## Запуск

```bash
npm start
```

Перед запуском обязательно задать `ADMIN_PASSWORD`.

Для VDS production рекомендуется:

- Node API: `127.0.0.1:8080`;
- Caddy: публичные `80/443`;
- HTTPS endpoint игры: `https://135.106.209.40`;
- firewall: закрыть 8080 снаружи;
- резервное копирование `data/state.json`.

## API

- `GET /health`
- `GET /api/game/ping`
- `POST /api/player/register`
- `GET /api/player/bootstrap`
- `GET /api/game/bootstrap`
- `POST /api/game/sync`
- `POST /api/game/purchase`
- `POST /api/game/reward`
- `POST /api/game/referral`
- `POST /api/game/season`
- `POST /api/player/action`
- `POST /api/player/sync` — только чтение/сверка authoritative snapshot; клиентский snapshot не записывается
- `GET /api/config`
- `GET /api/rating`
- `GET /api/notifications/poll`
- DEV CENTER admin API

## HTTPS

См. `deploy/README_HTTPS.md` и `deploy/setup_https_ip.sh`.
