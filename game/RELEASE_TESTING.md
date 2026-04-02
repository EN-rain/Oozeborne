# Windows Friend-Test Build

## Client Configuration
- The game reads `server_config.cfg`.
- In the editor, it uses `res://server_config.cfg`.
- In exported builds, it first looks for `server_config.cfg` next to the `.exe`.
- If no config file is found, it falls back to `127.0.0.1:7350`.

## Export Steps
1. Open the Godot project in `game/`.
2. Export `Windows Desktop`.
3. The preset outputs to `build/windows/NewGame.exe`.
4. Copy `server_config.example.cfg` next to the `.exe`.
5. Rename it to `server_config.cfg`.
6. Set `host` to the host machine's public IP or domain.

## Host Machine Checklist
1. Start Docker Desktop.
2. Run `docker compose up -d` in `main_server/`.
3. Confirm Nakama is healthy with `docker ps`.
4. Port forward TCP `7350` on your router to the host PC.
5. Allow TCP `7350` through Windows Firewall.
6. Find your public IP.
7. Put that public IP into each tester's `server_config.cfg`.

## Notes
- Players only need port `7350`.
- Port `7351` is only for the Nakama admin console.
- `addons/godot_mcp` is excluded from Windows export and is not required for gameplay.
