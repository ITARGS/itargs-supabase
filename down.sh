#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLIENTS_ROOT="${ROOT_DIR}/clients"

echo "==> DOWN: stopping services"

# Stop clients first
if [[ ! -d "${CLIENTS_ROOT}" ]]; then
  echo "-> No clients directory, skipping clients"
else
  shopt -s nullglob
  CLIENT_DIRS=( "${CLIENTS_ROOT}"/* )

  VALID_CLIENT_DIRS=()
  for d in "${CLIENT_DIRS[@]}"; do
    [[ -d "$d" && -f "$d/docker-compose.yml" ]] && VALID_CLIENT_DIRS+=( "$d" )
  done

  if (( ${#VALID_CLIENT_DIRS[@]} == 0 )); then
    echo "-> No client stacks found"
  else
    echo "-> Stopping client stacks"
    for (( i=${#VALID_CLIENT_DIRS[@]}-1; i>=0; i-- )); do
      client_dir="${VALID_CLIENT_DIRS[$i]}"
      client_name="$(basename "${client_dir}")"
      echo "   - ${client_name}"
      ( cd "${client_dir}" && docker compose down )
    done
  fi
fi

# Stop Caddy (optional)
if [[ -d "${ROOT_DIR}/caddy" && -f "${ROOT_DIR}/caddy/docker-compose.yml" ]]; then
  echo "-> Stopping Caddy"
  ( cd "${ROOT_DIR}/caddy" && docker compose down )
else
  echo "-> Caddy not found, skipping"
fi

echo "==> DOWN complete"
