# Server Architecture

## Stack

The backend is the **Moon Server** — a fully custom, containerised game backend running under `moon_server/`.

| Service | Language | Purpose |
|---|---|---|
| `game-server` | Go | Authoritative 20Hz WebSocket simulation |
| `lobby-api` | Node.js | REST API — auth, rooms, profiles, admin |
| `admin-portal` | Next.js | Moon Control Center |
| `postgres` | — | Persistent player data |
| `redis` | — | Session state, room registry, pub/sub |
| `adminer` | — | Database browser (dev only) |

All services are defined in `moon_server/docker-compose.yml`.

---

## Ports

| Port | Service | Purpose |
|------|---------|---------|
| 3000 | lobby-api | REST API for all client/admin calls |
| 8080 | game-server | Authoritative WebSocket simulation |
| 3001 | admin-portal | Moon Control Center |
| 5432 | postgres | Persistent data storage |
| 6379 | redis | Session, rooms, pub/sub |
| 8081 | adminer | DB browser (dev only) |

---

## Docker Compose Modes

### Development (default)

`docker-compose.yml` is the local/dev stack.

Characteristics:
- All services on the same Docker network
- Hot-reload enabled for `lobby-api` (nodemon) and `game-server` (air)
- `adminer` included for database inspection
- Environment loaded from `.env`

### Production (GCP Later)

To be deployed on GCP:
- `lobby-api` → Cloud Run
- `game-server` → GCE VM or Managed Instance Group
- `redis` → Memorystore
- `postgres` → Cloud SQL
- Images pushed from the same Dockerfiles used locally (environment parity)

---

## Postgres Schema

Database schema is defined in `db/migrations/001_init.sql`.

### Key tables

| Table | Purpose |
|---|---|
| `players` | user_id, email, username, created_at |
| `profiles` | display_name, cosmetics, class unlocks |
| `user_roles` | role_level (0 = player, 1 = admin, 2 = superadmin) |
| `progression` | level, xp, coins |
| `bans` | ban records with expiry |
| `mob_configs` | Live-tunable mob stats (hp, speed, damage, xp_reward) |
| `wave_configs` | Wave definitions — mob weights, count, duration |
| `match_sessions` | Per-match metadata |
| `match_results` | Per-player match outcomes |
| `staff_logs` | Audit log for every admin action |
| `friends` | Friend requests and accepted pairs |
| `chat_messages` | Global and DM chat history |

---

## Redis Usage

Redis keys used at runtime:

| Key Pattern | Purpose |
|---|---|
| `session:{token}` | JWT session validation |
| `room:{room_code}` | Room → game-server WS URL mapping |
| `presence:{user_id}` | Online/offline indicator (TTL-based) |
| `room_members:{room_id}` | Live player list per room |
| `config_updates` | Pub/sub channel for live mob stat updates from admin portal |
| `global_chat` | Pub/sub channel for global chat broadcast |
| `user_messages:{user_id}` | Pub/sub channel for DMs |

---

## Lobby API — Routes

### Auth
- `POST /auth/register` — email/password registration, returns JWT
- `POST /auth/login` — returns JWT
- `POST /auth/logout` — invalidates session in Redis

### Rooms
- `POST /rooms/create` — creates room code, stores in Redis, returns `{ room_code, ws_url }`
- `POST /rooms/join` — resolves room code to `{ room_id, ws_url }`

### Profiles
- `GET /profiles/me` — current player profile + progression

### Admin
- `GET /admin/players/search?q=` — search players (returns `is_online` from Redis)
- `PATCH /admin/players/:id/ban` — ban a player
- `POST /admin/players/:id/kick` — kick from active room
- `GET /admin/mobs/:mob_type` — get mob stats
- `PATCH /admin/mobs/:mob_type` — update mob stats (live)
- `POST /admin/broadcast` — send global message to all clients

---

## Game Server — Tick Loop (20Hz)

Every 50ms:

1. **Input dequeue** — validate and apply player inputs (speed cap, cooldowns, bounds)
2. **Mob AI step** — follow flow-field / steering per mob type
3. **Collision check** — spatial hash for players + mobs + projectiles
4. **Damage + loot** — XP, drop tables, coin rewards
5. **Interest filter (AOI)** — per-player cull
6. **Delta snapshot** — diff vs last snapshot, pack, broadcast per-player slice

### Match State Machine

```
LOBBY → PRE_WAVE → IN_WAVE → UPGRADE_PHASE → (loop) → RESULTS
```

- `UPGRADE_PHASE` exits when **all players ready** or **60s timeout** (host can force)
- Host transfer occurs automatically if host disconnects

### Op Codes (Client → Server)

| Code | Name | Description |
|---|---|---|
| 1 | OP_INPUT | Movement, attack flags, rotation, seq |
| 2 | OP_START_GAME | Host only — begin match |
| 3 | OP_UPGRADE_SELECT | Item/upgrade selection during upgrade phase |
| 4 | OP_PLAYER_READY | Toggle ready state |
| 5 | OP_VOTE_KICK | Initiate vote kick against a user_id |

### Op Codes (Server → Client)

| Code | Name | Description |
|---|---|---|
| 10 | OP_STATE | Delta snapshot — tick, player vitals, mob states |
| 11 | OP_SYNC_ALL | Full world dump on join/reconnect |
| 12 | OP_PLAYER_JOIN | Player joined the room |
| 13 | OP_PLAYER_LEAVE | Player left the room |
| 14 | OP_WAVE_START | Wave begins |
| 15 | OP_WAVE_END | Wave cleared |
| 16 | OP_MOB_SPAWN | New mob spawned |
| 17 | OP_MOB_DIE | Mob killed |
| 18 | OP_GAME_OVER | Match ended — results + rewards |
| 19 | OP_PLAYER_RECONNECTING | Teammate disconnecting (15s grace) |
| 20 | OP_VOTE_STATUS | Current kick vote tally |

---

## Admin Portal — Moon Control Center

A Next.js dashboard at `http://localhost:3001` with views:

| View | Description |
|---|---|
| Dashboard | Server health, active rooms, live player count |
| Player Database | Search players, view email/username/creation date, Online/Offline status |
| Tuning → Enemies | Live mob stat editor (HP, speed, damage, XP) |
| Tuning → Items | Shop item catalogue |
| Tuning → Classes | Class + subclass stat and skill editor |
| Broadcast | Send global server announcements |
| Graveyard | Ban / kick players by user ID with audit log |

---

## Deployment Commands

```bash
# Start full stack
docker compose up --build

# Rebuild one service
docker compose build --no-cache admin-portal
docker compose up -d admin-portal

# View logs
docker compose logs -f lobby-api
docker compose logs -f game-server

# Reset everything (drops all data)
docker compose down -v && docker compose up --build
```
