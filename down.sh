#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLIENTS_ROOT="${ROOT_DIR}/clients"

echo "==> DOWN: stopping services"

if [[ -d "${CLIENTS_ROOT}" ]]; then
  shopt -s nullglob
  CLIENT_DIRS=( "${CLIENTS_ROOT}"/* )

  VALID=()
  for d in "${CLIENT_DIRS[@]}"; do
    [[ -d "$d" && -f "$d/docker-compose.yml" ]] && VALID+=( "$d" )
  done

  if (( ${#VALID[@]} > 0 )); then
    echo "-> Stopping client stacks"
    for (( i=${#VALID[@]}-1; i>=0; i-- )); do
      client_dir="${VALID[$i]}"
      client_name="$(basename "${client_dir}")"
      echo "   - ${client_name}"
      ( cd "${client_dir}" && docker compose down )
    done
  else
    echo "-> No client stacks found"
  fi
else
  echo "-> No clients directory, skipping clients"
fi

if [[ -d "${ROOT_DIR}/caddy" && -f "${ROOT_DIR}/caddy/docker-compose.yml" ]]; then
  echo "-> Stopping Caddy"
  ( cd "${ROOT_DIR}/caddy" && docker compose down )
else
  echo "-> Caddy not found, skipping"
fi

echo "==> DOWN complete"
