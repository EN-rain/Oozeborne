# Nakama Game Server Setup

## Quick Start

### 1. Start the Server
```bash
docker-compose up -d
```

### 2. Access the Console
- **Web Console**: http://localhost:7351
- **Username**: admin
- **Password**: password

### 3. Server Ports
- **7350**: Client API (game connections)
- **7351**: Web Console (admin panel)
- **7349**: GRPC API

### 4. Godot Integration
Add the Nakama Godot addon to your game:
```
https://github.com/heroiclabs/nakama-godot
```

Connect from Godot:
```gdscript
var client := Nakama.create_client("defaultkey", "127.0.0.1", 7350, "http")
var session := await client.authenticate_email_async("user@example.com", "password")
```

## Commands

### Start Server
```bash
docker-compose up -d
```

### Stop Server
```bash
docker-compose down
```

### View Logs
```bash
docker-compose logs -f nakama
```

### Reset Database
```bash
docker-compose down -v
docker-compose up -d
```

## Friend-Test Hosting

### Required Player Port
- `7350/TCP`: game clients connect here

### Not Required For Players
- `7351/TCP`: Nakama admin console only
- `7349/TCP`: gRPC API only

### Port Forwarding Checklist
1. Start the stack with `docker-compose up -d`
2. Confirm Nakama is healthy with `docker ps`
3. Forward `7350/TCP` from your router to the PC running Docker
4. Allow `7350/TCP` through Windows Firewall
5. Find your public IP or domain
6. Put that host into the client's `server_config.cfg`

### Tester Distribution
- Export the Windows build from the `game` project
- Place `server_config.cfg` next to the exported `.exe`
- Send both files to testers

## Cloudflare Tunnel

Use Cloudflare Tunnel if you do not want router port forwarding for friend testing.

### What It Publishes
- Public hostname: `https://game.example.com`
- Local origin: `http://localhost:7350`

### Host Setup
1. Install `cloudflared`
2. Log in: `cloudflared tunnel login`
3. Create a tunnel: `cloudflared tunnel create nakama-game`
4. Create a DNS route: `cloudflared tunnel route dns nakama-game game.example.com`
5. Copy `main_server/cloudflared/config.example.yml` to `%USERPROFILE%\\.cloudflared\\config.yml`
6. Replace `YOUR_TUNNEL_ID`, `YOUR_TUNNEL_UUID.json`, and `game.example.com`
7. Run the tunnel: `cloudflared tunnel run nakama-game`

### Client Config
Use this in the exported build's `server_config.cfg`:
```cfg
[server]
host="game.example.com"
port=443
scheme="https"
server_key="defaultkey"
```

### Notes
- `cloudflared` must keep running while players are connected
- Nakama still listens locally on `7350`
- The admin console on `7351` does not need to be exposed publicly

## Features Available
- User Authentication (Email, Device, Social)
- Real-time Multiplayer
- Matchmaking
- Leaderboards
- Friends System
- Chat
- Storage
- Cloud Save
