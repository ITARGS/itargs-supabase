#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./down-all.sh
#   ./down-all.sh --purge

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLIENTS_ROOT="${ROOT_DIR}/clients"
MODE="${1:-}"

PURGE="false"
if [[ "${MODE}" == "--purge" ]]; then
  PURGE="true"
elif [[ -n "${MODE}" ]]; then
  echo "Usage: $0 [--purge]"
  exit 1
fi

echo "==> DOWN-ALL (purge=${PURGE})"

# Stop clients
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
    echo "-> Stopping all client stacks"
    for (( i=${#VALID_CLIENT_DIRS[@]}-1; i>=0; i-- )); do
      client_dir="${VALID_CLIENT_DIRS[$i]}"
      client_name="$(basename "${client_dir}")"
      echo "   - ${client_name}"
      if [[ "${PURGE}" == "true" ]]; then
        ( cd "${client_dir}" && docker compose down -v )
      else
        ( cd "${client_dir}" && docker compose down )
      fi
    done
  fi
fi

# Stop Caddy
if [[ -d "${ROOT_DIR}/caddy" && -f "${ROOT_DIR}/caddy/docker-compose.yml" ]]; then
  echo "-> Stopping Caddy"
  ( cd "${ROOT_DIR}/caddy" && docker compose down )
else
  echo "-> Caddy not found, skipping"
fi

echo "==> DOWN-ALL complete"
if [[ "${PURGE}" == "true" ]]; then
  echo "NOTE: All client volumes were deleted"
fi
