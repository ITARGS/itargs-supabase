#!/usr/bin/env bash
set -euo pipefail

CLIENT="${1:-}"
if [[ -z "$CLIENT" ]]; then
  echo "Usage: ./tools/delete-client.sh <client-name>"
  exit 1
fi

CLIENT="$(echo "$CLIENT" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_-')"
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLIENT_DIR="$BASE_DIR/clients/$CLIENT"

if [[ ! -d "$CLIENT_DIR" ]]; then
  echo "Client not found: $CLIENT"
  exit 1
fi

echo "Stopping client containers: $CLIENT"
(cd "$CLIENT_DIR" && docker compose down -v --remove-orphans) || true

echo "Removing client folder: $CLIENT_DIR"
rm -rf "$CLIENT_DIR"

# Remove Caddy route
CADDY_DIR="$BASE_DIR/caddy"
CADDYFILE="$CADDY_DIR/Caddyfile"

if [[ -f "$CADDYFILE" ]]; then
  echo "Removing Caddy routes..."
  # Remove the client block from Caddyfile
  sed -i.bak "/# Client: $CLIENT/,/^$/d" "$CADDYFILE" 2>/dev/null || \
  sed -i '' "/# Client: $CLIENT/,/^$/d" "$CADDYFILE" 2>/dev/null || true
  
  # Reload Caddy if running
  if docker ps --format '{{.Names}}' | grep -qx 'caddy'; then
    echo "Reloading Caddy..."
    docker exec caddy caddy reload --config /etc/caddy/Caddyfile 2>/dev/null || \
    (cd "$CADDY_DIR" && docker compose restart) || true
  fi
fi

echo "✅ Client deleted: $CLIENT"
