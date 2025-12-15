#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLIENT="${1:-}"

if [[ -z "${CLIENT}" ]]; then
  echo "Usage: $0 <clientname>"
  exit 1
fi

# Normalize client name (same as create-client.sh)
CLIENT="$(echo "$CLIENT" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_-')"
if [[ -z "$CLIENT" ]]; then
  echo "Invalid client name."
  exit 1
fi

CLIENT_DIR="${ROOT_DIR}/clients/${CLIENT}"

echo "==> UP-ONE: ${CLIENT}"

# Ensure shared edge network exists
docker network inspect edge > /dev/null 2>&1 || docker network create edge > /dev/null

# Start Caddy (optional)
if [[ -d "${ROOT_DIR}/caddy" && -f "${ROOT_DIR}/caddy/docker-compose.yml" ]]; then
  echo "-> Starting Caddy (if not running)"
  ( cd "${ROOT_DIR}/caddy" && docker compose up -d )
else
  echo "-> Caddy not found, skipping"
fi

# Start client
if [[ ! -d "${CLIENT_DIR}" || ! -f "${CLIENT_DIR}/docker-compose.yml" ]]; then
  echo "Client not found: ${CLIENT_DIR}"
  exit 1
fi

echo "-> Starting client stack: ${CLIENT}"
( cd "${CLIENT_DIR}" && docker compose up -d )

echo
( cd "${CLIENT_DIR}" && docker compose ps ) || true
