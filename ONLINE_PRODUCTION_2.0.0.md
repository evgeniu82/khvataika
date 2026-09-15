# Хватайка 2.0.0 — Online Production

This build keeps version **2.0.0** permanently and enables the prepared online architecture.

## Authority
- Server is authoritative for game outcomes, economy, purchases, rewards, progress, referrals, missions, season and rating.
- Client remains responsible for UI, input, animation, physics presentation, audio and local settings application.
- HTTP is asynchronous; gameplay startup does not wait for a network response.
- Player operations use idempotency/action IDs.
- Server sessions automatically re-register after expiration.
- Stale unfinished game attempts older than 120 seconds are automatically released server-side.
- Maintenance mode is enforced by the server.

## Startup flow
1. Game loads local shell and player ID.
2. Server URL is taken from project configuration, never from an old save.
3. Connection/authentication starts in the background.
4. Registration returns the authoritative player snapshot plus the full 2.0.0 catalog/config once.
5. Subsequent syncs are small snapshots without the full catalog.
6. News/notifications/rating continue in background requests.

## Canonical content
- 72 toys
- 16 collections
- 54 shop items
- 130 achievements
- 8 internal VIP definitions; normal VIP UI remains **«СКОРО...»**

Legacy server catalog entries removed from the live state:
`collection_`, `collections_8`, `claws_3`, `claws_6`, `claws_10`.

## DEV CENTER
The existing brown DEV CENTER remains the single developer control center. In SERVER mode it uses the real admin API; in LOCAL DEV it remains available without a server for UI/testing.

## Server endpoint
Current packaged endpoint:
`http://135.106.209.40:8080`

For public release, switch the endpoint to HTTPS before distribution.
