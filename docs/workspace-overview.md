# Workspace Overview

## Repository Shape

```
proxy/
├── game/              # Godot 4.6 client
├── moon_server/       # Custom authoritative backend
├── docs/              # Architecture documentation
└── tools/             # Dev utilities
```

This is a single workspace with a Godot client and the Moon Server backend kept in the same repo.

---

## `game/`

The client project is a Godot 4.6 game configured by [project.godot](../game/project.godot).

Main directories:

- `addons/`: Godot plugins (Godot MCP plugin, etc.)
- `assets/`: art, shaders, imported textures, and generated slime assets
- `resources/`: engine resources — class definitions, skill trees, shop item data
- `scenes/`: `.tscn` scene graph definitions
- `scripts/`: GDScript source
- `codegen/`: legacy tool (no longer used)

### Most Important Client Subtrees

`game/scripts/`:

- `globals/`: autoload singletons (ClassManager, ShopManager, LevelSystem, etc.)
- `systems/game/`: main match orchestration and mob spawner
- `entities/`: player, enemies (archer, lancer, warden, slime, boss), projectiles, items
- `components/`: health and status effect primitives
- `resources/`: class, stats, and shop data models
- `ui/`: auth, menu, lobby, shop, pause, death

`game/scenes/`:

- `ui/`: menu flow and room lobby scenes
- `levels/`: gameplay map scenes
- `entities/player/`: slime player scene variants
- `entities/enemies/`: archer, lancer, warden, void warden scenes
- `effects/`: damage number and particle scenes

`game/resources/`:

- `data/shop_items.json`: all shop item definitions (consumables, upgrades, equipment, special)
- `skills/`: skill `.tres` resources organised by `main_class/subclass/`

---

## `moon_server/`

The full custom backend stack. Replaces all third-party game backend services.

| Service | Language | Port | Description |
|---|---|---|---|
| `game-server` | Go | `8080` | Authoritative 20Hz WebSocket simulation |
| `lobby-api` | Node.js | `3000` | REST API — auth, rooms, profiles, admin |
| `admin-portal` | Next.js | `3001` | Moon Control Center |
| `postgres` | — | `5432` | Persistent player data |
| `redis` | — | `6379` | Session state, room registry, pub/sub |
| `adminer` | — | `8081` | Database browser (dev only) |

Key files:

- `docker-compose.yml`: full local stack definition
- `.env.example`: environment variable template
- `db/migrations/001_init.sql`: full Postgres schema and seed data

### `lobby-api/src/routes/`

- `auth.js`: `/auth/register`, `/auth/login`
- `rooms.js`: `/rooms/create`, `/rooms/join`
- `profiles.js`: `/profiles/me`
- `friends.js`: `/friends/request`, `/friends/list`
- `chat.js`: `/chat/global`, `/chat/friend`
- `admin.js`: `/admin/*` (requires Admin role)

### `game-server/`

Go service implementing:
- WebSocket room session management
- 20Hz authoritative tick loop
- Player input validation and movement simulation
- Mob state tracking and wave management
- Delta snapshot broadcast

---

## `docs/`

Architecture documentation for the current implementation.

---

## Global Runtime Summary

The player path through the system:

1. `auth_menu.tscn` — JWT login/register via `lobby-api`
2. `main_menu.tscn` — host or join multiplayer room, or start local
3. `room_lobby.tscn` — class selection, party display, host controls
4. `main.tscn` — actual match, connected to `game-server` via WebSocket

On the server side:

1. Client POSTs to `lobby-api` to create or join a room by room code
2. `lobby-api` registers room in Redis, returns `ws_url` pointing to `game-server`
3. Client opens WebSocket to `game-server` with JWT auth
4. `game-server` runs the authoritative 20Hz loop: input → simulate → broadcast snapshots
5. Clients interpolate remote players from server snapshots

---

## Current Asset/Art Organisation

The player presentation layer uses slime scenes:

- `game/assets/shaders/slime_color.gdshader`
- `game/assets/sprites/Player/Slime/`
- `game/scenes/entities/player/slime_*.tscn`

The slime system is the main player presentation layer used by all class scenes.
