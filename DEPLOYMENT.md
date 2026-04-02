# Deployment Guide: Oracle Cloud Free Tier + Cloudflare Tunnel

This guide explains how to deploy the Nakama game server on **Oracle Cloud Free Tier** and expose it securely via **Cloudflare Tunnel** (no static IP or firewall rules needed).

## Architecture

```
[Godot Client] <---> [Cloudflare Tunnel] <---> [Oracle VPS (Nakama Docker)]
```

## Prerequisites

- Oracle Cloud Free Tier account (always free: 2 AMD VMs + 24GB RAM)
- Cloudflare account (free tier works)
- Domain name (optional but recommended) OR use `*.trycloudflare.com`

---

## Step 1: Oracle Cloud Free Tier Setup

### 1.1 Create Always-Free VM

1. Log in to [Oracle Cloud Console](https://cloud.oracle.com/)
2. Go to **Compute** → **Instances** → **Create Instance**
3. Configure:
   - **Name**: `nakama-server`
   - **Image**: Ubuntu 22.04 LTS (or Oracle Linux 8)
   - **Shape**: VM.Standard.E2.1.Micro (Always Free: 1 OCPU, 1GB RAM)
   - **Network**: Create new VCN or use existing
   - **SSH Keys**: Generate new or upload your public key
   - **Boot Volume**: 50GB (Always Free limit)
4. Click **Create**

### 1.2 Open Required Ports

1. Go to **Networking** → **Virtual Cloud Networks** → Your VCN
2. Click **Security Lists** → Default Security List
3. Add **Ingress Rules**:
   - Stateless: No
   - Source Type: CIDR
   - Source CIDR: `0.0.0.0/0`
   - IP Protocol: TCP
   - Destination Port Range: `7350` (Nakama HTTP)
   - Description: `Nakama HTTP API`

   Add another for WebSocket:
   - Destination Port Range: `7351` (Nakama WebSocket)
   - Description: `Nakama WebSocket`

### 1.3 Connect to VM

```bash
chmod 600 your-key.pem
ssh -i your-key.pem ubuntu@YOUR_INSTANCE_IP
```

---

## Step 2: Install Docker on Oracle VM

```bash
# Update packages
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify
docker --version
docker-compose --version
```

---

## Step 3: Deploy Nakama

### 3.1 Clone Repository

```bash
cd ~
git clone https://github.com/EN-rain/new-game.git
cd new-game/main_server
```

### 3.2 Start Nakama

```bash
# Using production compose (uses volumes for persistence)
docker-compose -f docker-compose.prod.yml up -d

# Or use the default for quick testing
docker-compose up -d
```

### 3.3 Verify Nakama is Running

```bash
# Check containers
docker ps

# Check logs
docker logs nakama

# Test API
curl http://localhost:7350/
```

---

## Step 4: Cloudflare Tunnel Setup

### 4.1 Install cloudflared

```bash
# Download and install cloudflared
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared.deb

# Or use the install script
curl -L --output cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
chmod +x cloudflared
sudo mv cloudflared /usr/local/bin/
```

### 4.2 Authenticate with Cloudflare

```bash
cloudflared tunnel login
```

This will give you a URL to open in your browser. Log in to Cloudflare and authorize.

### 4.3 Create and Configure Tunnel

```bash
# Create a tunnel named 'nakama-game'
cloudflared tunnel create nakama-game

# The command outputs a tunnel ID, save it!
# Example: 2f4a8b1c-9d6e-4f3a-8b2c-1d5e9f8a7b3c
```

### 4.4 Create Config File

```bash
sudo mkdir -p /etc/cloudflared

sudo tee /etc/cloudflared/config.yml << 'EOF'
tunnel: YOUR_TUNNEL_ID
 credentials-file: /home/ubuntu/.cloudflared/YOUR_TUNNEL_ID.json

ingress:
  # Nakama HTTP API
  - hostname: nakama.yourdomain.com
    service: http://localhost:7350
  # Nakama WebSocket
  - hostname: nakama-ws.yourdomain.com
    service: ws://localhost:7351
  # Default fallback
  - service: http_status:404
EOF
```

Or for quick testing without a custom domain:

```bash
# Just run the tunnel without config for a temporary URL
cloudflared tunnel --url http://localhost:7350
```

This gives you a URL like `https://something.trycloudflare.com`

### 4.5 Run Cloudflare Tunnel as Service

```bash
# Install as systemd service
sudo cloudflared service install

# Start the service
sudo systemctl start cloudflared
sudo systemctl enable cloudflared

# Check status
sudo systemctl status cloudflared

# View logs
sudo journalctl -u cloudflared -f
```

---

## Step 5: Configure Game Client

### 5.1 Copy the Config Template

```bash
cd ~/new-game/game

# Copy and edit the server config
cp exports/config.template.cfg exports/server_config.cfg
nano exports/server_config.cfg
```

### 5.2 Fill in Your Tunnel URL

```ini
[server]
host="your-tunnel.trycloudflare.com"
port=443
scheme="https"
server_key="defaultkey"
```

### 5.3 Build and Export Game

In Godot:
1. **Project** → **Export** → **Add** → **Windows Desktop** (or your target)
2. Enable **Embed PCK** for single-file export
3. Set export path to `exports/`
4. **Export Project**

---

## Step 6: Update MultiplayerManager

Your `MultiplayerManager` should load the config at runtime. Here's the pattern:

```gdscript
# In MultiplayerManager.gd
const CONFIG_PATH = "res://exports/server_config.cfg"

func load_server_config() -> Dictionary:
    var config = ConfigFile.new()
    var err = config.load(CONFIG_PATH)
    if err == OK:
        return {
            "host": config.get_value("server", "host", "localhost"),
            "port": config.get_value("server", "port", 7350),
            "scheme": config.get_value("server", "scheme", "http"),
            "server_key": config.get_value("server", "server_key", "defaultkey")
        }
    return default_config
```

---

## Production Checklist

- [ ] Change default `server_key` in production
- [ ] Enable SSL on Cloudflare (Full Strict mode)
- [ ] Set up Cloudflare Access rules (if needed)
- [ ] Configure Docker volumes for data persistence
- [ ] Set up log rotation: `sudo logrotate /etc/logrotate.d/nakama`
- [ ] Monitor with Cloudflare Analytics or UptimeRobot
- [ ] Backup database regularly

---

## Troubleshooting

### Tunnel Won't Connect
```bash
# Check logs
sudo journalctl -u cloudflared -n 50

# Verify tunnel is running
cloudflared tunnel info nakama-game

# Restart service
sudo systemctl restart cloudflared
```

### Nakama Won't Start
```bash
# Check logs
docker logs nakama

# Common issues:
# - Port already in use: sudo lsof -i :7350
# - Database not ready: docker logs cockroach
# - Permission issues: sudo chown -R $USER:$USER ~/new-game
```

### Game Can't Connect
1. Verify tunnel URL is correct in `server_config.cfg`
2. Check that scheme is `https` for Cloudflare Tunnel
3. Test with curl: `curl https://your-tunnel.trycloudflare.com/`
4. Check browser console for CORS errors (if using web export)

---

## Useful Commands

```bash
# Restart everything
sudo systemctl restart cloudflared
docker-compose -f ~/new-game/main_server/docker-compose.prod.yml restart

# Update deployment
cd ~/new-game && git pull
# Then restart services

# Monitor resources
htop
docker stats
```

---

## Free Tier Limits

| Resource | Limit |
|----------|-------|
| Oracle VM | 2 instances (1 OCPU + 1GB RAM each) |
| Oracle Storage | 200GB boot volumes |
| Cloudflare Tunnel | Unlimited (free tier) |
| Cloudflare Bandwidth | Unlimited |
| Nakama | 100 CCU (soft limit on free tier) |

For more players, consider upgrading Oracle to paid tier or using multiple free VMs with load balancing.
