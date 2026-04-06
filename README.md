# New Game

A Godot 4.6 multiplayer game with Nakama backend.

## Project Structure

```
proxy/
├── game/              # Godot 4.6 client
│   ├── src/           # GDScript source
│   ├── scenes/        # Scene definitions
│   ├── assets/        # Art, shaders, textures
│   └── resources/     # Engine resources
├── main_server/       # Nakama server config
│   ├── modules/       # Lua match handlers
│   └── docker-compose.yml
├── exports/           # Export config templates
└── docs/              # Architecture documentation
```

## Quick Start

### 1. Start the Server
```bash
cd main_server
docker-compose up -d
```

### 2. Access Nakama Console
- **URL**: http://localhost:7351
- **Username**: admin
- **Password**: password

### 3. Run the Game
1. Open `game/project.godot` in Godot 4.6
2. Press F5 to run

### Server Ports
| Port | Purpose |
|------|---------|
| 7350 | Client API (game connections) |
| 7351 | Web Console (admin panel) |
| 7349 | GRPC API |

## Features

- Email-authenticated players
- Room-based multiplayer with authoritative server
- Lobby system with class selection
- Player progression via `LevelSystem`
- Status effects, shop, coins
- Slime player variants with palette swap shader

## Documentation

- [Workspace Overview](docs/workspace-overview.md)
- [Game Architecture](docs/game-architecture.md)
- [Multiplayer Architecture](docs/multiplayer-architecture.md)
- [Server Architecture](docs/server-architecture.md)

## Server Commands

```bash
# Start
docker-compose up -d

# Stop
docker-compose down

# View logs
docker-compose logs -f nakama

# Reset database
docker-compose down -v && docker-compose up -d
```

## Requirements

- Godot 4.6
- Docker & Docker Compose
- (Optional) Go for codegen tool

## License

MIT
