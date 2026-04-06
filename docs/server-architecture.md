# Server Architecture

## Stack

The backend is a Nakama + CockroachDB setup under `main_server/`.

Primary server files:

- [docker-compose.yml](c:\Users\LENOVO\Desktop\proxy\main_server\docker-compose.yml:1)
- [docker-compose.prod.yml](c:\Users\LENOVO\Desktop\proxy\main_server\docker-compose.prod.yml:1)
- [README.md](c:\Users\LENOVO\Desktop\proxy\main_server\README.md:1)
- [modules/lobby.lua](c:\Users\LENOVO\Desktop\proxy\main_server\modules\lobby.lua:1)
- [modules/rpc_registry.lua](c:\Users\LENOVO\Desktop\proxy\main_server\modules\rpc_registry.lua:1)

## Compose Modes

### Development

[docker-compose.yml](c:\Users\LENOVO\Desktop\proxy\main_server\docker-compose.yml:1) is the local/dev stack.

Characteristics:

- local CockroachDB + Nakama
- hardcoded console credentials
- hardcoded `defaultkey` for socket/runtime
- ports exposed directly

### Production

[docker-compose.prod.yml](c:\Users\LENOVO\Desktop\proxy\main_server\docker-compose.prod.yml:1) is the deployment stack.

Characteristics:

- env-driven console and runtime credentials
- public `7350` and `7351`
- local-only CockroachDB port binding
- `modules/` mounted read-only into Nakama
- logs volume mounted

## Ports

Current documented port usage:

- `7350`: public HTTP/game API
- `7351`: Nakama web console
- `7349`: gRPC/internal service port

The repo’s own README correctly treats `7351` as admin-only and `7350` as the player-facing port.

## Console Credentials

The repo currently defines:

- dev compose: `admin / password`
- prod compose fallback: `admin / changeme`

In production, the running values depend on the container environment at creation time, not just the file on disk.

## Lua Runtime Modules

### `rpc_registry.lua`

[rpc_registry.lua](c:\Users\LENOVO\Desktop\proxy\main_server\modules\rpc_registry.lua:1) provides room registry RPCs.

It uses an in-memory `room_registry` table and registers:

- `create_room`
- `join_room`
- `delete_room`

Behavior:

- `create_room` creates an authoritative match with handler name `lobby`
- room code maps to Nakama `match_id`
- `join_room` resolves room code to stored `match_id`
- registry is in-memory only, so it lasts only while the server process stays alive

That means room discovery is not persisted across server restarts.

### `lobby.lua`

[lobby.lua](c:\Users\LENOVO\Desktop\proxy\main_server\modules\lobby.lua:1) is the authoritative match handler.

Important characteristics:

- fixed tick rate: `20`
- world bounds: `0..800` x `0..600`
- fixed spawn points near map center
- player radius and overlap blocking logic
- host-gated `start_game`

State stored per player:

- position
- velocity
- facing
- ign
- host flag
- input sequence
- attack flag
- dash flag
- attack rotation

## Server Match Behavior

At a high level:

1. `match_init` seeds host player state if host data is provided
2. `match_join_attempt` ensures the joining player has state and a spawn point
3. `match_join` broadcasts `OP_PLAYER_JOIN`
4. `match_loop` processes incoming messages
5. movement is simulated server-side at fixed speed
6. collision blocking prevents players overlapping or crossing through each other
7. an `OP_STATE` snapshot is broadcast every loop when players exist

## Message Handling

`lobby.lua` understands:

- `OP_INPUT`
- `OP_START_GAME`
- op code `0` for legacy JSON `player_info` metadata

This mirrors the client’s mixed authoritative-plus-legacy transition state.

## Important Constraints

The server currently uses:

- one hardcoded movement speed constant: `100.0`
- fixed map bounds
- in-memory room registry

So if gameplay stats or room persistence requirements change, both client and server assumptions may need updating.

## Deployment Notes

The repo assumes Docker deployment, but the exact command on the host may be either:

- `docker-compose`
- `docker compose`

That depends on the VM environment, not the repo itself.

## Operational Truths For This Repo

- The server is small and readable enough that `lobby.lua` is the main source of truth for gameplay authority.
- The RPC registry is lightweight and intentionally simple, but not durable.
- Console access is operational configuration, not game-user authorization.
