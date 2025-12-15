#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLIENTS_ROOT="${ROOT_DIR}/clients"

echo "==> UP: starting services"

if [[ -d "${ROOT_DIR}/caddy" && -f "${ROOT_DIR}/caddy/docker-compose.yml" ]]; then
  echo "-> Starting Caddy"
  ( cd "${ROOT_DIR}/caddy" && docker compose up -d )
else
  echo "-> Caddy not found, skipping"
fi

if [[ ! -d "${CLIENTS_ROOT}" ]]; then
  echo "-> No clients directory, skipping clients"
else
  shopt -s nullglob
  CLIENT_COMPOSES=( "${CLIENTS_ROOT}"/*/docker-compose.yml )

  if (( ${#CLIENT_COMPOSES[@]} == 0 )); then
    echo "-> No client stacks found"
  else
    echo "-> Starting client stacks"
    for compose_file in "${CLIENT_COMPOSES[@]}"; do
      client_dir="$(dirname "${compose_file}")"
      client_name="$(basename "${client_dir}")"
      echo "   - ${client_name}"
      ( cd "${client_dir}" && docker compose up -d )
    done
  fi
fi

echo "==> UP complete"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
