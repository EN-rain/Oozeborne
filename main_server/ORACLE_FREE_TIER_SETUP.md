# Oracle Free Tier Setup

Use this path when you want to run the Nakama server on an Oracle Cloud Always Free VM instead of your local PC.

## What You Need
- One Oracle Cloud Free Tier VM
- Ubuntu installed on that VM
- A public IPv4 address on the VM
- Ingress rules for `22/TCP` and `7350/TCP`
- Docker and Docker Compose plugin on the VM

## OCI Create Steps
1. Create a compute instance in your OCI home region.
2. Prefer `VM.Standard.A1.Flex` if capacity is available.
3. Choose Ubuntu.
4. Make sure the instance has a public IP.
5. Add ingress rules:
   - `22/TCP` from your IP for SSH
   - `7350/TCP` from `0.0.0.0/0` for players

## VM Bootstrap
SSH into the VM and run:
```bash
chmod +x oracle/bootstrap_ubuntu.sh
./oracle/bootstrap_ubuntu.sh
```

This installs Docker, Compose plugin, firewall rules, and enables the Docker service.

## Upload Server Files
From your Windows PC:
```powershell
scp -r C:\Users\LENOVO\Desktop\proxy\main_server ubuntu@YOUR_ORACLE_VM_PUBLIC_IP:~/
```

## Start Nakama
On the VM:
```bash
cd ~/main_server
chmod +x oracle/deploy_nakama.sh
./oracle/deploy_nakama.sh
```

## Verify
On the VM:
```bash
docker ps
docker compose logs -f nakama
curl http://localhost:7351
```

From another machine:
```text
http://YOUR_ORACLE_VM_PUBLIC_IP:7350
```

## Client Config
Copy `game/server_config.oracle.example.cfg` next to the exported `.exe` and rename it to `server_config.cfg`:
```cfg
[server]
host="YOUR_ORACLE_VM_PUBLIC_IP"
port=7350
scheme="http"
server_key="defaultkey"
```

## Send To Testers
Send these files:
- `NewGame.exe`
- `NewGame.pck`
- `server_config.cfg`

## Notes
- Do not use Oracle identity login URLs for the game client.
- Use the Oracle VM public IP only.
- `7351` is admin console only. Do not expose it unless you need it.
- If you later put Nginx or Cloudflare in front, then switch the client to `443` and `https`.
