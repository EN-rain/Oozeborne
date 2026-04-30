# Moon Server

> Authoritative game backend for the 4-player co-op survivors game. Replaces Nakama.

---

## Services

| Service | Language | Port | Description |
|---|---|---|---|
| `game-server` | Go | `8080` | Authoritative 20Hz WebSocket simulation |
| `lobby-api` | Node.js | `3000` | REST API — Auth, rooms, profiles, admin |
| `admin-portal` | Next.js | `3001` | Moon Control Center |
| `postgres` | — | `5432` | Persistent player data |
| `redis` | — | `6379` | Session state, room registry, pub/sub |
| `adminer` | — | `8081` | Database browser (dev only) |

---

## Quick Start

### 1. Copy the environment file
```bash
cp .env.example .env
```

### 2. Start the full stack
```bash
docker compose up --build
```

### 3. Verify services are healthy
```
http://localhost:3000/health   → Lobby API
http://localhost:8080/health   → Game Server
http://localhost:3001          → Moon Control Center
http://localhost:8081          → Adminer (DB browser)
```

### 4. Default Admin Credentials
- **URL**: `http://localhost:3001`
- **Username**: `admin`
- **Password**: `admin`

> ⚠️ Change the password immediately after first login via Admin Portal → Account Settings.

---

## Directory Structure

```
moon_server/
├── docker-compose.yml        # Full local stack
├── .env.example              # Environment variable template
│
├── db/
│   └── migrations/
│       └── 001_init.sql      # Full Postgres schema
│
├── game-server/              # Go — Authoritative 20Hz WS server
│   ├── main.go
│   ├── go.mod
│   └── Dockerfile
│
├── lobby-api/                # Node.js — REST API
│   ├── src/
│   │   ├── index.js          # Express app entrypoint
│   │   ├── db.js             # Postgres pool
│   │   ├── redis.js          # Redis client
│   │   ├── middleware/
│   │   │   └── auth.js       # JWT guards
│   │   └── routes/
│   │       ├── auth.js       # /auth/register, /auth/login
│   │       ├── rooms.js      # /rooms/create, /rooms/join
│   │       ├── profiles.js   # /profiles/me
│   │       ├── friends.js    # /friends/request, /friends/list
│   │       ├── chat.js       # /chat/global, /chat/friend
│   │       └── admin.js      # /admin/* (requires Admin role)
│   ├── package.json
│   └── Dockerfile
│
└── admin-portal/             # Next.js — Moon Control Center
    ├── app/
    │   ├── layout.tsx
    │   ├── page.tsx          # Login
    │   ├── dashboard/
    │   │   └── page.tsx      # Main dashboard
    │   └── globals.css       # Moon dark theme
    ├── next.config.js
    ├── tailwind.config.js
    ├── tsconfig.json
    └── Dockerfile
```

---

## OpCode Reference

### Client → Server
| Code | Name | Description |
|---|---|---|
| `1` | `OP_INPUT` | Movement + attack flags |
| `5` | `OP_START_GAME` | Host starts the match |
| `10` | `OP_PLAYER_READY` | Toggle ready state |
| `11` | `OP_UPGRADE_SELECT` | Pick upgrade item |
| `12` | `OP_VOTE_KICK` | Initiate a vote kick |
| `13` | `OP_EMOTE` | Trigger cosmetic emote |

### Server → Client
| Code | Name | Description |
|---|---|---|
| `0` | `OP_MESSAGE` | Legacy JSON message |
| `2` | `OP_STATE` | Full tick snapshot |
| `3` | `OP_PLAYER_JOIN` | Player joined room |
| `4` | `OP_PLAYER_LEAVE` | Player left room |
| `6` | `OP_SYNC_ALL` | Full state resync (reconnect) |
| `7` | `OP_WAVE_START` | Wave begins |
| `8` | `OP_WAVE_END` | Wave complete |
| `14` | `OP_MOB_SPAWN` | Mob spawned |
| `15` | `OP_MOB_DIE` | Mob died + loot payload |
| `16` | `OP_PLAYER_RECONNECTING` | Grace period countdown |
| `17` | `OP_VOTE_STATUS` | Vote kick tally |
| `18` | `OP_GAME_OVER` | Run ended + results |

---

## Match State Machine
```
LOBBY → PRE_WAVE → IN_WAVE → UPGRADE_PHASE → (repeat) → RESULTS
```
- `UPGRADE_PHASE` exits when **all players ready** or **60s timeout**.

## Key Rules
- **Tickrate**: 20Hz (50ms per tick)
- **World bounds**: 800×600
- **Disconnect grace**: 15 seconds
- **AFK timeout**: 120 seconds
- **Input queue max**: 10 (excess dropped)
- **Difficulty scaling**: `mob_hp × (0.7 + player_count × 0.3)`
