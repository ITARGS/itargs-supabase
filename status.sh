#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLIENTS_ROOT="${ROOT_DIR}/clients"

echo "==> STATUS"

# Caddy status
if [[ -d "${ROOT_DIR}/caddy" && -f "${ROOT_DIR}/caddy/docker-compose.yml" ]]; then
  echo
  echo "-> Caddy:"
  ( cd "${ROOT_DIR}/caddy" && docker compose ps || true )
else
  echo
  echo "-> Caddy: not found"
fi

# Clients status
echo
if [[ ! -d "${CLIENTS_ROOT}" ]]; then
  echo "-> Clients: directory not found"
  exit 0
fi

shopt -s nullglob
CLIENT_DIRS=( "${CLIENTS_ROOT}"/* )
VALID_CLIENT_DIRS=()
for d in "${CLIENT_DIRS[@]}"; do
  [[ -d "$d" && -f "$d/docker-compose.yml" ]] && VALID_CLIENT_DIRS+=( "$d" )
done

if (( ${#VALID_CLIENT_DIRS[@]} == 0 )); then
  echo "-> Clients: none found"
  exit 0
fi

echo "-> Clients:"
for d in "${VALID_CLIENT_DIRS[@]}"; do
  name="$(basename "$d")"
  echo
  echo "   [${name}]"
  ( cd "$d" && docker compose ps || true )
done
