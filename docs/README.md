# Documentation

This folder documents the current workspace from the code that is actually in the repo, not from intended design notes.

## Scope

The workspace has three top-level areas:

- `game/`: Godot 4.6 client
- `main_server/`: Nakama server config and Lua runtime
- `exports/`: export config templates

## Read These First

- [workspace-overview.md](c:\Users\LENOVO\Desktop\proxy\docs\workspace-overview.md): repo map and high-level responsibilities
- [game-architecture.md](c:\Users\LENOVO\Desktop\proxy\docs\game-architecture.md): Godot runtime flow and gameplay systems
- [multiplayer-architecture.md](c:\Users\LENOVO\Desktop\proxy\docs\multiplayer-architecture.md): auth, lobby, Nakama match flow, and sync model
- [server-architecture.md](c:\Users\LENOVO\Desktop\proxy\docs\server-architecture.md): Nakama compose setup and Lua server behavior
- [mcp-usage.md](c:\Users\LENOVO\Desktop\proxy\docs\mcp-usage.md): how MCP was used to verify Godot/editor/runtime behavior in this repo

## Current Entry Points

Client:

- Project config: [project.godot](c:\Users\LENOVO\Desktop\proxy\game\project.godot:1)
- Main scene: `res://scenes/ui/auth_menu.tscn`

Server:

- Dev stack: [docker-compose.yml](c:\Users\LENOVO\Desktop\proxy\main_server\docker-compose.yml:1)
- Prod stack: [docker-compose.prod.yml](c:\Users\LENOVO\Desktop\proxy\main_server\docker-compose.prod.yml:1)
- Match handler: [lobby.lua](c:\Users\LENOVO\Desktop\proxy\main_server\modules\lobby.lua:1)
- RPC registry: [rpc_registry.lua](c:\Users\LENOVO\Desktop\proxy\main_server\modules\rpc_registry.lua:1)

## What The Codebase Currently Builds

- Email-authenticated Godot client backed by Nakama
- Room-based multiplayer with authoritative server movement
- Lobby scene with class carousel and slime palette previews
- Class resources that override the spawned player scene
- Progression through `LevelSystem`
- Status effect, shop, coin, and enemy support systems
- Slime player variants driven by palette-swapped scenes and a shared shader

## Important Implementation Reality

The codebase mixes:

- older prototype-style gameplay code
- newer authoritative multiplayer flow
- data-driven class resources
- recent slime-scene/palette work

So the docs below describe the current implementation as-is, including places where systems overlap or are still transitional.
