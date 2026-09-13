# Khvataika 1.13.6 — server chain fix

This package keeps the existing 1.13.6 game and gray-screen fix intact and strengthens the online chain:

- Game HTTP client no longer parses transport errors, empty responses, or non-JSON error pages as JSON.
- Player notification polling now sends the player Bearer token.
- Expired player sessions automatically trigger re-registration and reconnection.
- The game retries player authentication when the server temporarily becomes unavailable.
- Server registration validates `player_id` and records `last_active_unix`.
- Server JSON responses expose `X-Khvataika-Version: 1.13.6`.
- Admin panel restores its saved admin token and handles non-JSON/network/401 responses safely.
- Existing server-authoritative state, admin controls, notifications, achievements, workshop, missions, season, rating, etc. are preserved.

## Server deployment

Upload/replace the repository files from this ZIP in GitHub. Then on the VDS pull the repository and restart the PM2 process `khvataika` so the server loads the new `server/server.js` and `server/public/index.html`.

Do not delete the existing `server/data/state.json`.
