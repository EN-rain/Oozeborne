# Multiplayer Architecture

## Overview

The client uses Nakama for:

- email authentication
- persistent session restore
- room creation and room-code join
- websocket match communication
- authoritative movement snapshots

The multiplayer implementation is split across:

- [multiplayer_manager.gd](c:\Users\LENOVO\Desktop\proxy\game\src\globals\multiplayer_manager.gd:1)
- [multiplayer_utils.gd](c:\Users\LENOVO\Desktop\proxy\game\src\globals\multiplayer_utils.gd:1)
- [network_messaging.gd](c:\Users\LENOVO\Desktop\proxy\game\src\globals\network_messaging.gd:1)
- [room_lobby.gd](c:\Users\LENOVO\Desktop\proxy\game\src\ui\room_lobby.gd:1)
- [main.gd](c:\Users\LENOVO\Desktop\proxy\game\src\systems\game\main.gd:1)

## Server Config Resolution

`MultiplayerManager` resolves server connection details from:

- built-in defaults
- `server_config.cfg`

Default client assumptions in code:

- host: `127.0.0.1`
- port: `7350`
- scheme: `https`
- server key: `defaultkey`

That means exported builds depend on the external `server_config.cfg` being correct.

## Authentication Flow

The auth path is:

1. `auth_menu.gd` checks saved session
2. if available, `MultiplayerManager.restore_saved_session()` restores or refreshes it
3. if not, the user logs in or registers through email/password
4. session data is stored in `user://auth_session.json` using encrypted file access

`MultiplayerManager` also emits `auth_state_changed`.

## Room Flow

From `main_menu.gd`:

- host path:
  - disconnect any old socket
  - connect to server
  - call room creation
  - switch to `room_lobby.tscn`
- join path:
  - disconnect any old socket
  - connect to server
  - join by room code
  - switch to `room_lobby.tscn`

## Lobby Responsibilities

[room_lobby.gd](c:\Users\LENOVO\Desktop\proxy\game\src\ui\room_lobby.gd:1) owns both UI and multiplayer behavior.

It currently handles:

- populating and refreshing player list state
- sending `player_info`
- receiving match state in the lobby
- local class selection
- broadcasting selected class name
- host-only `start_game`
- chat box widgets
- lobby title editing broadcast
- slime preview assignment for main classes

The current lobby also assigns a random slime variant per displayed class and applies it to the preview sprites through the slime shader.

## Match Transport Model

The game uses op codes defined in [multiplayer_utils.gd](c:\Users\LENOVO\Desktop\proxy\game\src\globals\multiplayer_utils.gd:1):

- `1`: input
- `2`: authoritative state snapshot
- `3`: player join
- `4`: player leave
- `5`: start game

The design is authoritative:

- client sends input
- server simulates movement
- server broadcasts snapshots
- client interpolates remote players
- client reconciles local player against server sequence ids

## Client-Side Prediction and Interpolation

`MultiplayerUtils` tracks:

- `_remote_players`
- `_pending_inputs`
- local player weak ref
- ping/jitter/interpolation delay

It provides:

- remote player registration
- target update buffering
- interpolation with delayed render timeline
- attack/dash state carry-over for remote visuals
- input loop at 20 Hz
- pending input replay after authoritative snapshots

Remote players are visually driven from server-facing state, not local input.

## Main Match Responsibilities

[main.gd](c:\Users\LENOVO\Desktop\proxy\game\src\systems\game\main.gd:1) still contains a lot of networking logic directly.

It currently:

- connects to `received_match_state`
- connects to `received_match_presence`
- listens to `MultiplayerManager.player_joined`
- spawns remote players from manager state
- handles server snapshots
- handles legacy JSON messages like `player_info`, `player_attack`, `ping`, `pong`

This means networking ownership is not fully centralized yet.

## Current Implementation Boundaries

### `MultiplayerManager`

Owns:

- Nakama client/session/socket lifecycle
- room code and match id
- player dictionary
- match phase
- selected local class and subclass
- stored remote `PlayerClass` values by user id

### `MultiplayerUtils`

Owns:

- op codes
- interpolation buffers
- reconciliation state
- ping/jitter data
- input send loop

### `room_lobby.gd`

Owns:

- lobby scene UI
- class select broadcast
- slime preview rendering
- host start button behavior

### `main.gd`

Owns:

- in-match scene state
- remote spawn orchestration
- snapshot application
- gameplay scene transition behavior

## Practical Risks In Current Code

The current codebase has several multiplayer overlap points worth documenting:

1. Presence handling exists in both `MultiplayerManager` and `main.gd`.
2. Lobby-selected slime scene overrides are not fully authoritative unless explicitly transmitted.
3. Client prediction and class-based movement modifiers must stay in sync.
4. Some network behavior is still split between op-code snapshots and older JSON message paths.

These are implementation realities, not just theoretical concerns.

## Recommended Reading Order For Multiplayer Changes

If changing multiplayer behavior, read in this order:

1. [multiplayer_manager.gd](c:\Users\LENOVO\Desktop\proxy\game\src\globals\multiplayer_manager.gd:1)
2. [multiplayer_utils.gd](c:\Users\LENOVO\Desktop\proxy\game\src\globals\multiplayer_utils.gd:1)
3. [room_lobby.gd](c:\Users\LENOVO\Desktop\proxy\game\src\ui\room_lobby.gd:1)
4. [main.gd](c:\Users\LENOVO\Desktop\proxy\game\src\systems\game\main.gd:1)
5. [main_server/modules/lobby.lua](c:\Users\LENOVO\Desktop\proxy\main_server\modules\lobby.lua:1)
