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

echo "✅ Client deleted: $CLIENT"
