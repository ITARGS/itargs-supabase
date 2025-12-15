#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Stopping all client stacks..."
shopt -s nullglob
CLIENT_DIRS=( "${ROOT_DIR}"/clients/* )

# Keep only directories that have docker-compose.yml
VALID_CLIENT_DIRS=()
for d in "${CLIENT_DIRS[@]}"; do
  [[ -d "$d" && -f "$d/docker-compose.yml" ]] && VALID_CLIENT_DIRS+=( "$d" )
done

if (( ${#VALID_CLIENT_DIRS[@]} == 0 )); then
  echo "No clients found under ${ROOT_DIR}/clients/*"
else
  for (( i=${#VALID_CLIENT_DIRS[@]}-1; i>=0; i-- )); do
    client_dir="${VALID_CLIENT_DIRS[$i]}"
    client_name="$(basename "${client_dir}")"
    echo "  -> Stopping client: ${client_name}"
    ( cd "${client_dir}" && docker compose down )
  done
fi

echo "==> Stopping Caddy..."
( cd "${ROOT_DIR}/caddy" && docker compose down )

echo "Done."
