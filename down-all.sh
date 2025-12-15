#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./down-all.sh           -> stops all clients (keeps volumes) + stops caddy
#   ./down-all.sh --purge   -> stops all clients + deletes volumes + stops caddy

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODE="${1:-}"

PURGE="false"
if [[ "${MODE}" == "--purge" ]]; then
  PURGE="true"
elif [[ -n "${MODE}" ]]; then
  echo "Usage: $0 [--purge]"
  exit 1
fi

echo "==> Stopping all client stacks (purge=${PURGE})..."
shopt -s nullglob
CLIENT_DIRS=( "${ROOT_DIR}"/clients/* )

VALID_CLIENT_DIRS=()
for d in "${CLIENT_DIRS[@]}"; do
  [[ -d "$d" && -f "$d/docker-compose.yml" ]] && VALID_CLIENT_DIRS+=( "$d" )
done

if (( ${#VALID_CLIENT_DIRS[@]} == 0 )); then
  echo "No clients found under ${ROOT_DIR}/clients/*"
else
  # Stop in reverse order
  for (( i=${#VALID_CLIENT_DIRS[@]}-1; i>=0; i-- )); do
    client_dir="${VALID_CLIENT_DIRS[$i]}"
    client_name="$(basename "${client_dir}")"
    echo "  -> ${client_name}"
    if [[ "${PURGE}" == "true" ]]; then
      ( cd "${client_dir}" && docker compose down -v )
    else
      ( cd "${client_dir}" && docker compose down )
    fi
  done
fi

echo "==> Stopping Caddy..."
( cd "${ROOT_DIR}/caddy" && docker compose down )

echo "Done."
if [[ "${PURGE}" == "true" ]]; then
  echo "NOTE: All client volumes were deleted."
fi
