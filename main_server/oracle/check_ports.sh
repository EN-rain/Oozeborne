#!/usr/bin/env bash
set -euo pipefail

echo "Listening sockets:"
sudo ss -ltnp | grep -E ':(22|7350|7351)\b' || true

echo
echo "Docker containers:"
docker ps

echo
echo "Local Nakama checks:"
curl -I --max-time 5 http://localhost:7350 || true
curl -I --max-time 5 http://localhost:7351 || true
