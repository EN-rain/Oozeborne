# Multiplayer Architecture

## Overview

The client connects to two Moon Server services:

- **`lobby-api`** (REST, port 3000): authentication, room create/join, profiles
- **`game-server`** (WebSocket, port 8080): authoritative 20Hz real-time simulation

The multiplayer implementation is split across:

- [multiplayer_manager.gd](../game/scripts/globals/multiplayer_manager.gd)
- [multiplayer_utils.gd](../game/scripts/globals/multiplayer_utils.gd)
- [network_messaging.gd](../game/scripts/globals/network_messaging.gd)

---

## Server Config Resolution

`MultiplayerManager` resolves server connection details from:

- built-in defaults
- `server_config.cfg` (overrides for exported builds)

Default client assumptions:

| Setting | Default |
|---|---|
| Lobby API host | `127.0.0.1:3000` |
| Game Server WS | `ws://127.0.0.1:8080` |

Exported builds should point `server_config.cfg` at the production URLs.

---

## Authentication Flow

1. `auth_menu.gd` checks for a stored JWT in `user://auth_session.json`
2. If valid (not expired), `MultiplayerManager.restore_saved_session()` restores it
3. If not, user logs in or registers via `POST /auth/login` or `POST /auth/register`
4. JWT is stored locally using encrypted file access

`MultiplayerManager` emits `auth_state_changed` on every transition.

---

## Room Flow

From `main_menu.gd`:

**Host path:**
1. `POST /rooms/create` → receives `{ room_code, ws_url }`
2. Store room code, switch to `room_lobby.tscn`
3. Open WebSocket to `ws_url` with JWT

**Join path:**
1. `POST /rooms/join` with room code → receives `{ room_id, ws_url }`
2. Switch to `room_lobby.tscn`
3. Open WebSocket to `ws_url` with JWT

---

## Lobby Responsibilities

`room_lobby.gd` owns both UI and match-entry behaviour.

It handles:

- populating and refreshing player list
- sending `player_info` (class, subclass, slime variant)
- receiving match state in the lobby phase
- local class selection and subclass browsing
- broadcasting selected class name to all lobby members
- host-only `start_game` control
- lobby title editing and chat widgets
- slime preview assignment per class via shader

---

## Match Transport Model

Op codes are defined in `multiplayer_utils.gd`:

### Client → Server

| Code | Name | Payload |
|---|---|---|
| 1 | OP_INPUT | `seq`, `move_x`, `move_y`, `attack`, `dash`, `rotation` |
| 2 | OP_START_GAME | host only |
| 3 | OP_UPGRADE_SELECT | `item_id`, `slot_index` |
| 4 | OP_PLAYER_READY | toggle |
| 5 | OP_VOTE_KICK | `target_user_id` |

### Server → Client

| Code | Name | Payload |
|---|---|---|
| 10 | OP_STATE | `tick`, `wave_num`, `player_vitals`, `mob_states` |
| 11 | OP_SYNC_ALL | full world dump on join/reconnect |
| 12 | OP_PLAYER_JOIN | `user_id`, `class`, `position` |
| 13 | OP_PLAYER_LEAVE | `user_id` |
| 14 | OP_WAVE_START | `wave_num`, `mob_count` |
| 15 | OP_WAVE_END | `wave_num` |
| 16 | OP_MOB_SPAWN | `mob_id`, `type`, `position` |
| 17 | OP_MOB_DIE | `mob_id`, `killer_id` |
| 18 | OP_GAME_OVER | results + rewards |
| 19 | OP_PLAYER_RECONNECTING | `user_id`, `grace_ms` |
| 20 | OP_VOTE_STATUS | kick vote tally |

The design is fully authoritative:

- Client sends input at 20Hz
- Server simulates movement, validates, and applies
- Server broadcasts delta snapshots back to all clients
- Client interpolates remote players from snapshot data
- Client reconciles local player against server sequence IDs

---

## Client-Side Prediction and Interpolation

`MultiplayerUtils` tracks:

- `_remote_players` — remote player state buffers
- `_pending_inputs` — unacknowledged local inputs
- local player weak reference
- ping / jitter / interpolation delay

It provides:

- remote player registration
- target update buffering with interpolation delay
- smooth interpolated playback of remote positions
- attack/dash state carry-over for remote visuals
- input send loop at 20Hz
- pending input replay after authoritative snapshots

Remote players are visually driven from server-facing state, not local input.

---

## Disconnect Handling

- **15-second grace period** on disconnect — player stays in world (frozen)
- All teammates receive `OP_PLAYER_RECONNECTING` with countdown
- If player reconnects within 15s, receives `OP_SYNC_ALL` and resumes
- If grace period expires, `OP_PLAYER_LEAVE` is broadcast and mob scaling adjusts

---

## Death States

| State | Behaviour |
|---|---|
| `ALIVE` | Normal gameplay |
| `DOWNED` | 15-second revive window for teammates |
| `DEAD` | Spectate until wave end, then respawn |

Game over occurs when all 4 players are `DEAD` simultaneously.

---

## Practical Implementation Notes

1. `MultiplayerManager` owns the JWT, room code, and WebSocket lifecycle.
2. `MultiplayerUtils` owns op codes, interpolation buffers, and reconciliation.
3. `room_lobby.gd` owns lobby UI and class selection broadcast.
4. `main.gd` owns in-match scene orchestration and snapshot application.

---

## Recommended Reading Order For Multiplayer Changes

1. [multiplayer_manager.gd](../game/scripts/globals/multiplayer_manager.gd)
2. [multiplayer_utils.gd](../game/scripts/globals/multiplayer_utils.gd)
3. [network_messaging.gd](../game/scripts/globals/network_messaging.gd)
4. [room_lobby.gd](../game/scripts/ui/room_lobby.gd) *(if it exists)*
5. [main.gd](../game/scripts/systems/game/main.gd) *(if it exists)*
6. `moon_server/game-server/` — Go authoritative server source
