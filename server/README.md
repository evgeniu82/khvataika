# Хватайка — authoritative server v2

Сервер является источником истины для аккаунтов, экономики, инвентаря, наград, рейтинга, миссий, сезона, событий, промокодов и покупок.

## Запуск

```bash
npm start
```

Перед запуском обязательно задать `ADMIN_PASSWORD`. Сервер намеренно не имеет production-пароля по умолчанию.

## Основные API

- `GET /health`
- `POST /api/player/register` — выдаёт серверный player token
- `GET /api/player/bootstrap`
- `POST /api/player/action` — идемпотентные серверные игровые операции
- `GET /api/config`
- `GET /api/rating`
- `GET /api/notifications/poll`
- `POST /api/admin/login`
- `GET/POST /api/admin/state`
- `GET /api/admin/dashboard`
- `POST /api/admin/player`
- `POST /api/admin/notify`
- `GET /api/admin/notifications`
- `GET /api/admin/audit`
- `GET /api/admin/transactions`
- `POST /api/admin/transaction/reverse`

## Защита

Клиентский `/api/player/sync` больше не принимает и не записывает баланс, XP, рейтинг или инвентарь. Он возвращает серверный снимок. Изменения проходят через типизированные действия и `action_id`/идемпотентность.

Для production рекомендуется HTTPS reverse proxy (Nginx/Caddy), firewall VDS и резервное копирование `data/state.json`.
