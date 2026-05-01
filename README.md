# Oozeborne

A Godot 4.6 multiplayer 4-player co-op survivors game backed by **Moon Server** — a fully custom, containerised game backend.

## Quick Start (Remote Server)

```bash
cd ~/Oozeborne
git reset --hard
git pull
cd moon_server
docker compose build --no-cache admin-portal
docker compose up -d admin-portal
```

## Project Structure

```
proxy/
├── game/              # Godot 4.6 client
│   ├── scripts/       # GDScript source
│   ├── scenes/        # Scene definitions
│   ├── assets/        # Art, shaders, textures
│   ├── resources/     # Class, skill, and item data
│   └── codegen/       # Legacy codegen tool (unused)
├── moon_server/       # Custom authoritative backend
│   ├── game-server/   # Go — 20Hz WebSocket simulation
│   ├── lobby-api/     # Node.js — REST API (auth, rooms, admin)
│   ├── admin-portal/  # Next.js — Moon Control Center
│   ├── db/            # Postgres migrations
│   └── docker-compose.yml
├── docs/              # Architecture documentation
└── tools/             # Dev utilities
```

## Quick Start (Local Dev)

### 1. Copy the environment file
```bash
cd moon_server
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
http://localhost:3001          → Moon Control Center (Admin Portal)
http://localhost:8081          → Adminer (DB browser)
```

### 4. Default Admin Credentials
- **URL**: `http://localhost:3001`
- **Username**: `admin`
- **Password**: `admin`

> ⚠️ Change the password immediately after first login via Admin Portal → Staff Management.

### 5. Run the Game
1. Open `game/project.godot` in Godot 4.6
2. Press F5 to run

## Server Ports

| Port | Service | Purpose |
|------|---------|---------|
| 3000 | lobby-api | REST API — auth, rooms, profiles, admin |
| 8080 | game-server | Authoritative 20Hz WebSocket simulation |
| 3001 | admin-portal | Moon Control Center |
| 5432 | postgres | Persistent player data |
| 6379 | redis | Session state, room registry, pub/sub |
| 8081 | adminer | Database browser (dev only) |

## Features

- Email-authenticated players via JWT
- Room-based multiplayer with authoritative 20Hz server
- Lobby system with class selection and slime variant previews
- 5 main classes with 18 subclasses and full skill trees
- Player progression via `LevelSystem`
- Status effects, shop, coins, and upgrade phases
- Slime player variants with palette swap shader
- Live mob tuning and admin portal with real-time monitoring

## Documentation

- [Workspace Overview](docs/workspace-overview.md)
- [Game Architecture](docs/game-architecture.md)
- [Multiplayer Architecture](docs/multiplayer-architecture.md)
- [Server Architecture](docs/server-architecture.md)

## Server Commands

```bash
# Start full stack
docker compose up --build

# Start in background
docker compose up -d

# Stop
docker compose down

# View all logs
docker compose logs -f

# View specific service logs
docker compose logs -f lobby-api
docker compose logs -f game-server

# Reset database (destroys all data)
docker compose down -v && docker compose up --build

# Rebuild a specific service
docker compose build --no-cache admin-portal
docker compose up -d admin-portal
```

## Requirements

- Godot 4.6
- Docker & Docker Compose
- (Optional) Go toolchain for local game-server development
- (Optional) Node.js for local lobby-api development

## License

MIT
