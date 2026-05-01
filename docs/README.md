# Documentation

This folder documents the current workspace based on the code that is actually in the repo.

## Workspace Areas

| Area | Description |
|---|---|
| `game/` | Godot 4.6 client |
| `moon_server/` | Custom authoritative backend |
| `docs/` | Architecture documentation |
| `tools/` | Dev utilities |

## Read These First

- [workspace-overview.md](workspace-overview.md) — repo map and high-level responsibilities
- [game-architecture.md](game-architecture.md) — Godot runtime flow and gameplay systems
- [multiplayer-architecture.md](multiplayer-architecture.md) — auth, lobby, WebSocket match flow, and sync model
- [server-architecture.md](server-architecture.md) — Moon Server stack, routes, tick loop, and database schema

## Current Entry Points

**Client:**
- Project config: `game/project.godot`
- Main scene: `res://scenes/ui/auth_menu.tscn`

**Server:**
- Full stack: `moon_server/docker-compose.yml`
- DB schema: `moon_server/db/migrations/001_init.sql`
- Lobby API routes: `moon_server/lobby-api/src/routes/`
- Game Server: `moon_server/game-server/`
- Admin Portal: `moon_server/admin-portal/`

## What The Codebase Currently Builds

- Email-authenticated Godot client connected to Moon Server via JWT
- Room-based multiplayer with authoritative 20Hz WebSocket simulation
- Lobby scene with class carousel and slime palette previews
- 5 main classes with 18 subclasses and full skill trees
- Progression through `LevelSystem`
- Status effects, shop (JSON-driven), coins, and enemy systems
- 6 tunable mob types: slime, common, lancer, archer, warden, boss
- Slime player variants driven by palette-swapped scenes and a shared shader
- Moon Control Center (Admin Portal) with live mob tuning, player database, and Graveyard
