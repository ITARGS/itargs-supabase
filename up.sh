#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> UP: starting services"

# Ensure shared edge network exists
docker network inspect edge >/dev/null 2>&1 || docker network create edge >/dev/null

# Start Caddy first (shared reverse proxy)
if [[ -f "$BASE_DIR/caddy/docker-compose.yml" ]]; then
  echo "-> Starting Caddy"
  docker compose -f "$BASE_DIR/caddy/docker-compose.yml" up -d
else
  echo "-> Caddy not found, skipping"
fi

# Start each client
if [[ -d "$BASE_DIR/clients" ]]; then
  for d in "$BASE_DIR/clients"/*; do
    [[ -d "$d" ]] || continue
    [[ -f "$d/docker-compose.yml" ]] || continue
    echo "-> Starting client: $(basename "$d")"
    (cd "$d" && docker compose up -d)
  done
else
  echo "-> No clients directory, skipping"
fi
