#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Starting Caddy..."
( cd "${ROOT_DIR}/caddy" && docker compose up -d )

echo "==> Starting all client stacks..."
shopt -s nullglob
CLIENT_COMPOSES=( "${ROOT_DIR}"/clients/*/docker-compose.yml )

if (( ${#CLIENT_COMPOSES[@]} == 0 )); then
  echo "No clients found under ${ROOT_DIR}/clients/*/docker-compose.yml"
else
  for compose_file in "${CLIENT_COMPOSES[@]}"; do
    client_dir="$(dirname "${compose_file}")"
    client_name="$(basename "${client_dir}")"
    echo "  -> Starting client: ${client_name}"
    ( cd "${client_dir}" && docker compose up -d )
  done
fi

echo
echo "==> Running containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
