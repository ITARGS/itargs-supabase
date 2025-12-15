#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./tools/delete-client.sh <clientname> [--purge]
#
# --purge does:
#   - docker compose down -v (deletes volumes)
#   - removes the clients/<client> folder
#
# Without --purge:
#   - docker compose down (keeps volumes)
#   - keeps the folder (so you can re-run later)

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
CADDYFILE="${ROOT_DIR}/caddy/Caddyfile"

if [[ ! -d "${CLIENT_DIR}" ]]; then
  echo "Client folder not found: ${CLIENT_DIR}"
  exit 1
fi

# Stop stack
echo "Stopping stack for client: ${CLIENT}"
if [[ "${MODE}" == "--purge" ]]; then
  ( cd "${CLIENT_DIR}" && docker compose down -v )
else
  ( cd "${CLIENT_DIR}" && docker compose down )
fi

# Remove Caddyfile block safely:
# We delete from the line that starts with "api.<client>.itargs.com {" until the matching "}" line.
if [[ -f "${CADDYFILE}" ]]; then
  echo "Updating Caddyfile to remove route for api.${CLIENT}.itargs.com"
  tmp="$(mktemp)"
  awk -v host="api.${CLIENT}.itargs.com" '
    BEGIN {skip=0}
    # start skipping at host block
    $0 ~ "^"host"[[:space:]]*\\{" {skip=1; next}
    # stop skipping at closing brace
    skip==1 && $0 ~ "^\\}" {skip=0; next}
    # print lines not skipped
    skip==0 {print}
  ' "${CADDYFILE}" > "${tmp}"
  mv "${tmp}" "${CADDYFILE}"
else
  echo "Warning: Caddyfile not found, skipping route removal."
fi

# Optionally remove folder
if [[ "${MODE}" == "--purge" ]]; then
  echo "Purging folder: ${CLIENT_DIR}"
  rm -rf "${CLIENT_DIR}"
fi

# Restart caddy to apply changes
echo "Restarting Caddy..."
( cd "${ROOT_DIR}/caddy" && docker compose restart )

echo
echo "✅ Deleted client: ${CLIENT} (${MODE:-kept volumes})"
if [[ "${MODE}" != "--purge" ]]; then
  echo "Note: volumes were kept. Use --purge to delete volumes + folder."
fi
