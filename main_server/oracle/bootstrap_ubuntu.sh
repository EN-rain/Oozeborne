#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

sudo apt update
sudo apt install -y docker.io docker-compose-plugin curl ca-certificates ufw

sudo systemctl enable --now docker

if id -nG "$USER" | grep -qw docker; then
  echo "User already in docker group"
else
  sudo usermod -aG docker "$USER"
  echo "Added $USER to docker group. Re-login or run: newgrp docker"
fi

sudo ufw allow 22/tcp
sudo ufw allow 7350/tcp
sudo ufw --force enable

echo
echo "Bootstrap complete."
echo "Next steps:"
echo "1. Re-login or run: newgrp docker"
echo "2. Upload ~/main_server"
echo "3. Run: ./oracle/deploy_nakama.sh"
