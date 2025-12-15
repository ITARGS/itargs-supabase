#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./tools/delete-client.sh <clientname> [--purge]
#
# Without --purge: stops containers, keeps volumes + folder
# With --purge:    stops containers + deletes volumes + deletes folder

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLIENT="${1:-}"
MODE="${2:-}"

if [[ -z "${CLIENT}" ]]; then
  echo "Usage: $0 <clientname> [--purge]"
  exit 1
fi

if ! [[ "${CLIENT}" =~ ^[a-z0-9-]+$ ]]; then
  echo "Client name must match: ^[a-z0-9-]+$"
  exit 1
fi

CLIENT_DIR="${ROOT_DIR}/clients/${CLIENT}"
CADDY_DIR="${ROOT_DIR}/caddy"
CADDYFILE="${CADDY_DIR}/Caddyfile"

if [[ ! -d "${CLIENT_DIR}" || ! -f "${CLIENT_DIR}/docker-compose.yml" ]]; then
  echo "Client not found: ${CLIENT_DIR}"
  exit 1
fi

echo "Stopping client stack: ${CLIENT}"
if [[ "${MODE}" == "--purge" ]]; then
  ( cd "${CLIENT_DIR}" && docker compose down -v )
else
  ( cd "${CLIENT_DIR}" && docker compose down )
fi

# Remove Caddyfile block (markers)
BEGIN="# BEGIN CLIENT ${CLIENT}"
END="# END CLIENT ${CLIENT}"

if [[ -f "${CADDYFILE}" ]]; then
  cp "${CADDYFILE}" "${CADDYFILE}.bak.$(date +%Y%m%d-%H%M%S)"
  tmp="$(mktemp)"
  awk -v begin="$BEGIN" -v end="$END" '
    $0 == begin {skip=1; next}
    $0 == end {skip=0; next}
    skip!=1 {print}
  ' "${CADDYFILE}" > "${tmp}"
  mv "${tmp}" "${CADDYFILE}"
  echo "Removed Caddy route for api.${CLIENT}.itargs.com"
else
  echo "Caddyfile not found, skipping Caddy update."
fi

if [[ "${MODE}" == "--purge" ]]; then
  echo "Purging client folder: ${CLIENT_DIR}"
  rm -rf "${CLIENT_DIR}"
fi

# Reload Caddy if running
if [[ -d "${CADDY_DIR}" && -f "${CADDY_DIR}/docker-compose.yml" ]]; then
  if docker ps --format '{{.Names}}' | grep -qx 'caddy'; then
    ( cd "${CADDY_DIR}" && docker compose exec -T caddy caddy reload --config /etc/caddy/Caddyfile ) \
      || ( cd "${CADDY_DIR}" && docker compose restart ) || true
  fi
fi

echo "✅ Deleted client: ${CLIENT} ${MODE:-"(kept volumes)"}"
