# ХВАТАЙКА 1.14.2 — LOCAL / OFFLINE COMPLETE

This build is the local-first milestone. The server code is retained for the later online phase, but gameplay is explicitly offline and does not use server authority.

## Local systems
- Profile and local save/load
- Main arcade machine and claw movement
- Prize physics, capture chances and rarity
- Toys, duplicates, collections and collection rewards
- Shop: claws, claw skins, toy skins, machine skins, upgrades and VIP
- Workshop: modules, blueprints, calibration, overclock and timed jobs
- Daily/weekly missions and login rewards
- Achievements and progression/XP
- Chests and keys
- Seasonal pass, seasons, holidays and events
- Promo codes
- Local referral flow
- Local leaderboard/rating presentation
- News and in-game live systems panels
- Return bonus
- Settings, music playlist and UI/game SFX
- Android background notification integration where supported

## Offline safety
- `OFFLINE_MODE = true`
- `SERVER_AUTHORITATIVE = false`
- server URL is forced empty when loading an old save
- old player token is cleared on load
- all local rewards/purchases use local save state

## Important
The web admin panel is retained for the future Selectel/server phase. It is not required to launch or play the local game.
