# Moon Server Plan (Local-First → GCP Later)

## 0) Why This Doc Exists

This repo currently ships a Godot 4.6 client backed by **Nakama** (`main_server/`) with an authoritative match loop in Lua (`main_server/modules/lobby.lua`). The goal is to **remove Nakama** and replace it with **our own services**:

- `game-server` (Go): authoritative realtime server at **20Hz**, WebSocket transport
- `lobby-api` (Node.js or Go): REST API for auth, matchmaking, rooms, profiles, leaderboards, **admin actions**
- `admin-portal` (React/Next.js): Web-based dashboard for staff and moderators
- `redis`: session + room state + pub/sub
- `postgres`: persistent player data, progression, saves, **roles, and bans**

We will build and validate everything **using Docker Compose** to ensure environment parity between local development and GCP production.

---

## 1) Current State (What We Are Replacing)

### Today’s runtime

- **Client** connects to Nakama HTTP + socket (defaults in `game/scripts/globals/multiplayer_manager.gd`).
- **Rooms** are created/joined via Nakama RPCs (`main_server/modules/rpc_registry.lua`).
- **Realtime** state is authoritative (server simulates movement at 20Hz and broadcasts snapshots).
- **Op codes** already exist client-side (`game/scripts/globals/network_messaging.gd`):
  - `0`: JSON message (legacy / misc)
  - `1`: input
  - `2`: state snapshot
  - `3`: player join
  - `4`: player leave
  - `5`: start game

### What Nakama is currently doing for us

- Email/password auth + session restore (client stores encrypted session locally)
- Authoritative match host + tick scheduling
- Storage and server-side “RPC” entrypoints
- Operational extras (console, runtime keys, etc.)
- **Admin/Moderator system** (kick, ban, teleport, role management)
- **Combat Validation** (attack cooldowns and range checks)

---

## 2) Target Architecture (Local First)

### Local Compose (mirrors GCP 1:1)

**Godot clients (1–4)** connect to:

- `lobby-api` (`:3000`) for:
  - auth
  - matchmaking / room create + join
  - profiles / progression / leaderboard reads
- `game-server` (`:8080`) via WebSocket for:
  - room session
  - authoritative 20Hz simulation
  - state broadcast (delta snapshots / AOI)
- `admin-portal` (`:3001`) for:
  - live player/room monitoring
  - role management & banning
  - global broadcasts

Backends:

- `redis` (`:6379`) for:
  - session state
  - room registry (durable across process restarts)
  - pub/sub between game-server instances (future scaling)
- `postgres` (`:5432`) for persistent data
- optional `adminer` (`:8081`) for DB browsing in development

### GCP later (defer until local is stable)

- Cloud Run: `lobby-api`
- GCE VM (or managed instance group): `game-server`
- Memorystore: Redis
- Cloud SQL: Postgres
- GCS: replays/log archives/assets (optional)
- Firebase: auth/JWT (optional, if chosen)

---

## 3) Server Tick Loop (20Hz) — Target Behavior

On every tick (every 50ms):

1. **Input dequeue**: validate + apply player inputs
2. **Flow field step** (optional initially): refresh at ~500ms cadence
3. **Mob AI step** (optional initially): follow flow-field / steering
4. **Collision check**: spatial hash buckets (players + mobs + projectiles)
5. **Damage + loot**: XP, drop tables, rewards
6. **Interest filter (AOI)**: per-player cull (what each player is allowed to see)
7. **Delta snapshot + broadcast**: diff vs last snapshot, pack, send per-player slice

**Important:** We will implement this incrementally. Phase 1 only needs authoritative **movement + snapshots** to replace the current Nakama loop.

---

## 4) Goals / Non-Goals

### Goals (local milestone success criteria)

- 1–4 local Godot clients can:
  - authenticate (dev auth initially)
  - create/join a room by code
  - connect to WS room session
  - send inputs and receive authoritative snapshots at 20Hz
  - see join/leave + start game events reliably
- Server is restart-safe:
  - room registry is not lost on process restart (unlike the current in-memory registry)
- Clear operational workflow:
  - `docker compose up` brings up everything
  - logs/metrics make tick and networking visible

### 4.5) Co-op Survival Architecture (The "Game Director")

To support a 4-player survivors/brawler genre, the server acts as the **Director**:

- **Wave Manager**: Authoritative timer and enemy count. Triggers `OP_WAVE_START` and `OP_WAVE_END`.
- **Authoritative Mob State**: 
  - Server tracks `mob_id`, `type`, `pos`, and `hp` for every enemy.
  - Clients only render; the server decides when a mob dies.
- **Shared XP/Loot**:
  - XP is collected into a shared pool (or proximity-based) and broadcasted.
  - Server validates item/upgrade picks during the `UPGRADE_PHASE`.
- **Player Vitals**:
  - Server tracks `hp` and `death_state`.
  - Handles respawn timers or "Game Over" if all 4 players are down.

### Non-goals (for the local-first iteration)

- Global scaling / multi-region deployments
- Anti-DDoS beyond basic rate limiting and sane defaults
- Full feature parity with all future “mob AI / loot / replay” features (we stage these)

---

## 5) Compatibility Strategy (How We Avoid Breaking the Game)

### Stepwise replacement (recommended)

1. **Keep the current op-code model** (`0..5`) as the first target.
2. Replace Nakama socket with a **direct WebSocket** client in Godot (or a small adapter layer).
3. Keep message shapes as close as possible initially (JSON first), then migrate to MsgPack later.

### Protocol evolution plan

- **Phase A (bring-up):** JSON messages, matching current fields (`move_x`, `move_y`, `seq`, etc.).
- **Phase B (performance):** introduce MsgPack + binary snapshots (delta + AOI).
- **Phase C (scale):** add reliability rules (ack/seq), compression, and cross-instance pub/sub.

---

## 6) Workstreams (Parallelizable Tracks)

### A) Inventory + Requirements (must do first)

- Audit all Nakama usage in client:
  - auth, session restore, socket connect, match join, RPC calls
- **Client-Side Cleanup**:
  - **Remove Admin Role & Perks**: Purge all "Admin" flags, logic, and gameplay perks from the Godot client. The client will no longer have any "Admin" state.
  - **Remove Slash Commands**: Delete logic for `/kick`, `/ban`, etc., from chat/input handlers.
  - **Remove Stealth Join**: Remove any code allowing admins to join matches "without notice."
- Inventory server-side responsibilities currently in:
  - `main_server/modules/lobby.lua`
  - `main_server/modules/rpc_registry.lua`
- Produce a “Parity Checklist”:
  - features we must match to ship local replacement (minimum)
  - features we can defer (nice-to-have)

### B) API Contracts (lobby-api)

Define and freeze (versioned) endpoints for local testing:

- `POST /auth/register` (or dev-only stub)
- `POST /auth/login`
- `POST /rooms/create` → returns `room_code`, `room_id`, `ws_url`
- `POST /rooms/join` (room_code) → returns `room_id`, `ws_url`
- `POST /matchmaking/queue` (optional early)
- `GET /profiles/me`
- `GET /leaderboard` (later)

Also define:

- JWT/session format
- “player identity” key (stable `user_id`)
- how `lobby-api` tells `game-server` to “spawn/assign room” (direct call, queue, or redis state)
- **Admin API**: endpoints for `kick`, `ban`, `set_role`, `broadcast`

### C) Realtime Protocol (game-server)

Define message types (versioned):

  - `OP_INPUT` (`seq`, movement, attack_flags, rotation)
  - `OP_UPGRADE_SELECT` (payload: `item_id`, `slot_index`)
  - `OP_START_GAME` (host only)
  - `OP_VOTE_KICK` (target: `user_id`)
  - `OP_EMOTE` (id: `emote_id`)
  - `OP_PLAYER_READY` (toggle ready state)
  - `OP_MESSAGE` (legacy JSON: chat)
- Server → client:
  - `OP_STATE` (Snapshot: `tick`, `wave_num`, `wave_timer`, `player_vitals` (incl. `ping_rtt`), `player_builds`, `mob_states`)
  - `OP_SYNC_ALL` (Full World Dump: includes `seed`, `match_context`, `all_players`, `all_mobs`)
  - `OP_PLAYER_JOIN`, `OP_PLAYER_LEAVE`
  - `OP_PLAYER_READY` (Broadcast: `user_id`, `is_ready`)
  - `OP_PLAYER_RECONNECTING` (Countdown for teammates during 15s grace)
  - `OP_WAVE_START`, `OP_WAVE_END`
  - `OP_MOB_SPAWN`, `OP_MOB_DIE`
  - `OP_VOTE_STATUS` (Current tally for a kick)
  - `OP_GAME_OVER` (Final run results + reward breakdown)

Define server rules:

- validation (movement bounds, speed, cooldowns, **attack range/rate**)
- **Match State Machine**: `LOBBY` → `PRE_WAVE` → `IN_WAVE` → `UPGRADE_PHASE` → `RESULTS`.
  - *Ready Rule*: Transition from `UPGRADE_PHASE` occurs when **All players are ready** OR **60s timeout** (host can force).
- **Death States**: `ALIVE`, `DOWNED` (15s revive window), `DEAD` (Spectate until wave end).
- **Disconnect Grace**: **15s grace period**. Player stays in world (frozen) before `OP_PLAYER_LEAVE` triggers. Teammates see `OP_PLAYER_RECONNECTING`.
- **AFK Detection**: Server marks players "IDLE" after 120s of no input.
- **Difficulty Scaling**: Mob HP and Spawn Counts scale by `0.7x + (player_count * 0.3x)`.
- **Rate Limiting**: Max **10 queued inputs** per player. Excess are dropped.
- **Admin Portal Auth**: Monitoring WS requires a **Short-lived Portal Token** generated by `lobby-api` for SuperAdmins.
- ordering and idempotency (seq handling)
- disconnection handling (grace period vs immediate removal)
- host selection + host transfer (if host leaves)

#### E) Gameplay Constants (Parity)
To match `lobby.lua`, the Go server must implement:
- `TICKRATE = 20`
- `WORLD_BOUNDS`: `X[0, 800]`, `Y[0, 600]`
- `SPAWN_POINTS`: `(360,300), (440,300), (400,240), (400,360)`
- `PLAYER_RADIUS = 6.0`
- `ATTACK_COOLDOWN_MS = 500`
- `ATTACK_RANGE = 60.0`

### D) Persistence (postgres)

Design tables (minimal → later):

- `players` (user_id, email/username, created_at)
- `profiles` (display name, cosmetics, class unlocks)
- `progression` (level, xp, coins)
- `saves` (JSONB blobs, versioned)
- **`mob_configs`** (mob_type, health, speed, damage, xp_reward)
- **`wave_configs`** (wave_num, mob_weights, count, duration) -- *Cached at room creation*.
- **`match_sessions`** (match_id, room_code, seed, wave_reached, player_count, duration)
- **`match_results`** (match_id, user_id, kills, dmg_dealt, coins_earned, xp_earned)
- **`staff_logs`** (log_id, admin_id, action_type, payload, created_at)
- **`user_roles`** (user_id, role_level)
- **`friends`** (user_a, user_b, status: 'pending'|'accepted')
- **`chat_messages`** (sender_id, recipient_id, channel_type: 'global'|'friend', message, created_at)
- **`bans`** (user_id, reason, banned_by, created_at)

Define migration strategy from Nakama storage (if any):

- export existing user data
- import into postgres
- verify integrity

### E) Social & Chat (Redis Pub/Sub + Postgres)

Implementation of persistent social features:

- **Global Chat**: 
  - Messages sent to `lobby-api` or `game-server`.
  - Broadcasted to all connected instances via Redis Pub/Sub `global_chat` channel.
  - Optionally saved to `chat_messages` in Postgres for history.
- **Friends System**:
  - `POST /friends/request` (user_id)
  - `GET /friends/list` (shows online status via Redis presence)
  - **Private Messaging**: Real-time delivery to a specific user's connection via Redis Pub/Sub `user_messages:{user_id}` channel.

### F) Redis (session + room state)

Use redis for:

- room registry: `room_code -> room_id -> server_instance`
- ephemeral room membership/presence
- session blacklisting / logout
- pub/sub (real-time chat delivery and coordination)

### F) Containerization Strategy (Docker)

To ensure "Moon Server" is production-ready and scalable:

- **Unified Stack**: All services (`lobby-api`, `game-server`, `admin-portal`, `redis`, `postgres`) run as Docker containers.
- **Service Discovery**: Internal communication between services happens via Docker network aliases (e.g., `lobby-api` connects to `DB_HOST=postgres`).
- **Hot Reloading**: Containers will use volume mounts and watcher tools:
  - **Go**: Uses `cosmtrek/air` for live-reloading inside the container.
  - **Node/Next.js**: Uses standard `dev` mode with filesystem polling.
- **Production Readiness**: The Dockerfiles created locally will be the exact same ones pushed to **Google Artifact Registry** for GCP deployment.

### G) Observability + Ops (local-first)

Minimum visibility:

- structured logs (room_id, user_id, tick_ms, send_bytes)
- tick timing histogram (p50/p95/p99)
- connection counts + room counts
- snapshot sizes and send rate

Phase later:

- Prometheus scrape + Grafana dashboard (optional)
- distributed tracing (OTel) for lobby-api + game-server coordination

### I) Moon Control Center (Admin Portal)

The **exclusive** platform for all Admin Roles and "Perks":

- **Identity Management**:
  - Search players by user_id, email, or IGN
  - **Super Admin Only**: Assign/Revoke Admin roles (staff accounts).
  - **Account Settings**: Change Admin/SuperAdmin passwords.
  - *Default Credentials*: `admin` / `admin` (Temporary Super Admin).
  - View ban history and apply new bans
- **Live Monitoring**:
  - List all active rooms and their current tick rates
  - View live player counts per instance
  - "Peek" into room logs (filtered by room_id)
- **Global Commands**:
  - Send global broadcast messages to all connected clients
  - Set "Maintenance Mode" (prevents new room creation)
  - Force-close suspicious rooms
- **Analytics**:
  - Simple chart for CCU (Concurrent Users) over time
  - Average session length and room lifespan
- **Live Tuning (Balance)**:
  - **Global Mob Tuner**: Real-time editor for mob base stats (HP, Speed, DMG).
  - **Active Room Interaction**: Click an active room to view live player progress and **Remote Spawn** mobs into that specific match.
  - **Lobby-Specific Overrides**: Temporarily buff/nerf mobs in a single active lobby to assist or challenge players.
  - **Live Reload**: Push changes instantly via Redis back-channel.

#### J) Design Suggestions for Moon Control Center
- **Live World View**: Use Redis Pub/Sub + WebSockets to show a real-time list of active matches with player counts and tick health.
- **Audit Logging**: Every admin action (ban, kick, role change) must be logged to a `staff_logs` table for accountability.
- **Maintenance Mode**: A global toggle in Redis that the `lobby-api` checks before allowing `room/create` calls.
- **Player "Deep Dive"**: A view that aggregates a player's history, progression, current match, and any previous reports or bans.
- **Config Broadcast**: When stats are modified in the Portal, it publishes to a `config_updates` Redis channel. The `game-server` listens and reloads values into memory instantly.
- **Projectile Authority**: 
  - **Decision**: **Server-side Hit Validation** with **Client-side Visuals**.
  - Client spawns visual projectiles; Server calculates collisions based on player attack timestamps and entity positions.
- **UI Aesthetic**: Use a dark-themed, glassmorphic dashboard (Next.js + Shadcn) to match the premium "Moon" branding.

---

## 7) Milestones (Local-First Execution Plan)

### M0 — Design Freeze (1–3 days)

- Deliverables:
  - parity checklist
  - endpoint specs (lobby-api)
  - realtime protocol v0 (JSON)
  - entity/state snapshot schema
- Acceptance:
  - we can point to a single doc and say “this is what we’re implementing first”

### M1 — Local Stack Boots (1 day)

- Deliverables:
  - docker compose with `redis`, `postgres`, `adminer`, placeholders for `lobby-api` and `game-server`
  - `.env` template
- Acceptance:
  - `docker compose up` starts dependencies and they are reachable

### M2 — Auth + Identity (2–4 days)

- Deliverables:
  - lobby-api returns a usable auth token (dev mode acceptable)
  - Godot can log in and store token locally (similar to current session restore)
- Acceptance:
  - client can restart and restore auth without manual re-login (dev mode)

### M3 — Rooms: Create/Join + Registry (2–4 days)

- Deliverables:
  - room codes generated and stored in redis
  - join resolves to a room + WS URL
- Acceptance:
  - room code survives lobby-api restart

### M4 — Realtime Bring-up (3–7 days)

- Deliverables:
  - game-server WS accepts `room_id` + auth token and joins player
  - join/leave broadcasts working
  - server runs authoritative 20Hz loop
  - input (OP 1) → snapshot (OP 2) works with seq reconciliation
- Acceptance:
  - 2–4 clients move smoothly with authoritative snapshots (local LAN)

### M5 — Feature Parity: Lobby + Start Game (2–5 days)

- Deliverables:
  - `player_info` broadcast support (ign, slime_variant, class selection)
  - host-gated `start_game`
  - lobby metadata (title, chat) if needed
- Acceptance:
  - existing lobby scene can function with minimal rework

### M6 — Snapshot Optimization (3–10 days, optional before GCP)

- Deliverables:
  - delta snapshots (diff vs last)
### Milestone 6: The Game Director (The Survival Core)
- Implement Wave Manager (timer, spawning mobs from cached `wave_configs`).
- Implement Player Vitals (HP tracking, `DOWNED` vs `DEAD` states).
- Implement Upgrade Phase (Gate next wave on `OP_PLAYER_READY` or timeout).
- Implement `OP_UPGRADE_SELECT` and server-side build validation.

### Milestone 7: Persistence & Progression (The "Save" Button)

- Deliverables:
  - postgres-backed profile/progression reads/writes
  - basic save/load paths wired from lobby-api
- Acceptance:
  - player data is durable across restarts

### M8 — Load/Soak + Hardening (ongoing)

- Deliverables:
  - scripted bot clients or headless harness
  - soak test: N rooms × 20Hz × 30 minutes, no tick drift
- Acceptance:
  - p99 tick time under budget on dev machine

---

## 8) Local Build/Run Guide (When We Start Implementation)

### Prereqs

- **Docker Desktop** (or Docker Engine + Compose)
- Godot 4.6 (for client testing)
- Go toolchain (optional, for local IDE linting)
- Node.js (optional, for local IDE linting)

### Default local ports (proposed)

- `lobby-api`: `3000`
- `game-server` WS: `8080`
- `redis`: `6379`
- `postgres`: `5432`
- `adminer`: `8081`

### “It Works” definition (local)

- Start stack → open 2–4 Godot clients → authenticate → create/join room → move and see each other in real-time.

---

## 9) Migration & Cutover Strategy (From Nakama)

### Two-track approach (recommended)

1. Keep Nakama stack runnable until the custom stack hits M5 parity.
2. Add a build-time or config-time switch in the client:
   - `backend=nakama` vs `backend=custom`
3. Run both stacks locally to compare behavior and identify parity gaps.

### Decommission checklist

- Remove Nakama addon dependency from the client (only after custom path is stable)
- Remove `main_server/` compose and Lua runtime
- Archive any data migration tooling (export/import) in `tools/`

---

## 11) Nakama Feature Gap Analysis (What is NOT in Moon Server yet)

Compared to the full Nakama suite, the following features are currently **omitted** from the Moon Server plan. If your game relies on these, we need to add them to the workstreams:

1. **Groups / Guilds**: Built-in logic for creating clans, managing membership, and group chat.
2. **Time-Windowed Leaderboards**: Nakama handles complex leaderboards that reset daily/weekly/monthly automatically.
3. **Tournaments**: Built-in logic for entry fees, reward distribution, and schedule management.
4. **In-App Notifications**: A system to send "Mail" or alerts to players that they see when they next log in.
7. **Hooks / Interceptors**: Nakama allows running logic *before* or *after* any system action (e.g., "Run this Go code before a user registers"). We will need a middleware pattern in `lobby-api` to match this.

---

## 12) Open Decisions (Pick Early)

1. **Auth provider:** dev-only auth → Firebase JWT → or fully custom email/password?
2. **Lobby-api language:** Node.js vs Go (choose based on team velocity + ecosystem)
3. **Protocol format:** JSON first (fast) → MsgPack later (performance)
4. **Room lifecycle ownership:** lobby-api vs game-server as source of truth
5. **State schema versioning:** how clients negotiate protocol changes

