#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> DOWN: stopping services"

# Stop clients
if [[ -d "$BASE_DIR/clients" ]]; then
  for d in "$BASE_DIR/clients"/*; do
    [[ -d "$d" ]] || continue
    [[ -f "$d/docker-compose.yml" ]] || continue
    echo "-> Stopping client: $(basename "$d")"
    (cd "$d" && docker compose down)
  done
fi

# Stop Caddy
if [[ -f "$BASE_DIR/caddy/docker-compose.yml" ]]; then
  echo "-> Stopping Caddy"
  docker compose -f "$BASE_DIR/caddy/docker-compose.yml" down
fi
