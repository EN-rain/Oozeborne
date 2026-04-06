# Workspace Overview

## Repository Shape

Top level:

- `game/`
- `main_server/`
- `exports/`

This is a single workspace with a Godot client and a Nakama backend kept in the same repo.

## `game/`

The client project is a Godot 4.6 game configured by [project.godot](c:\Users\LENOVO\Desktop\proxy\game\project.godot:1).

Main directories:

- `addons/`: plugins, including the Nakama addon and Godot MCP plugin
- `assets/`: art, shaders, imported textures, and generated slime assets
- `resources/`: engine resources outside `src/`
- `scenes/`: `.tscn` scene graph definitions
- `src/`: GDScript source
- `codegen/`: generated support files
- `ai/`: AI-related project content

### Most Important Client Subtrees

`game/src/`:

- `globals/`: autoload managers
- `systems/game/`: main match orchestration and mob spawner
- `entities/`: player, enemies, projectiles, items
- `components/`: health and status effect primitives
- `resources/`: class, stats, and shop data models
- `ui/`: auth, menu, lobby, shop, pause, death

`game/scenes/`:

- `ui/`: menu flow and room lobby scenes
- `levels/`: gameplay map scenes
- `entities/player/`: current slime player scene variants
- `entities/enemies/`: enemy scenes
- `effects/`: damage number and particle scenes

## `main_server/`

This folder is the Nakama server side.

Files present:

- [docker-compose.yml](c:\Users\LENOVO\Desktop\proxy\main_server\docker-compose.yml:1)
- [docker-compose.prod.yml](c:\Users\LENOVO\Desktop\proxy\main_server\docker-compose.prod.yml:1)
- [README.md](c:\Users\LENOVO\Desktop\proxy\main_server\README.md:1)
- [modules/lobby.lua](c:\Users\LENOVO\Desktop\proxy\main_server\modules\lobby.lua:1)
- [modules/rpc_registry.lua](c:\Users\LENOVO\Desktop\proxy\main_server\modules\rpc_registry.lua:1)

The server codebase is small and focused:

- one authoritative match handler
- one RPC registry for room creation/join/deletion
- dockerized CockroachDB + Nakama runtime

## `exports/`

This folder holds export-side config templates. It is supporting infrastructure, not the game runtime.

## Global Runtime Summary

The user path through the system is:

1. `auth_menu.tscn`
2. `main_menu.tscn`
3. `room_lobby.tscn` for hosted/joined multiplayer, or direct jump into gameplay for local start
4. `main.tscn` for the actual match

On the server side:

1. client calls RPC to create or join a room by room code
2. Nakama starts or locates a `lobby` authoritative match
3. clients join the match socket
4. the Lua match loop receives input op codes and broadcasts authoritative snapshots

## Current Asset/Art Organization

The newest art pipeline work is concentrated in:

- [slime_color.gdshader](c:\Users\LENOVO\Desktop\proxy\game\assets\shaders\slime_color.gdshader:1)
- `game/assets/sprites/Player/Slime/`
- `game/scenes/entities/player/slime_*.tscn`

The slime system is currently the main player presentation layer used by class scenes.
