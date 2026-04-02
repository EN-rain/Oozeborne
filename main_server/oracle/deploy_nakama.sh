#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"

docker compose pull
docker compose up -d

echo
echo "Containers:"
docker ps

echo
echo "Nakama health:"
docker compose logs --tail=30 nakama

echo
echo "Public game port should be 7350/TCP on the Oracle VM public IP."
