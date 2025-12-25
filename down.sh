#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

# Check if a specific client was specified
CLIENT_NAME="${1:-}"

if [[ -n "$CLIENT_NAME" ]]; then
  # Stop only the specified client
  CLIENT_DIR="$BASE_DIR/clients/$CLIENT_NAME"
  
  if [[ ! -d "$CLIENT_DIR" ]]; then
    echo "❌ ERROR: Client '$CLIENT_NAME' does not exist!"
    echo "Available clients:"
    ls -1 "$BASE_DIR/clients" 2>/dev/null || echo "  (no clients found)"
    exit 1
  fi
  
  if [[ ! -f "$CLIENT_DIR/docker-compose.yml" ]]; then
    echo "❌ ERROR: No docker-compose.yml found for client '$CLIENT_NAME'"
    exit 1
  fi
  
  echo "==> Stopping client: $CLIENT_NAME"
  (cd "$CLIENT_DIR" && docker compose down)
  echo "✅ Client '$CLIENT_NAME' stopped successfully"
  
else
  # Stop all clients and Caddy (original behavior)
  echo "==> DOWN: stopping all services"
  
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
  
  echo "✅ All services stopped"
fi
