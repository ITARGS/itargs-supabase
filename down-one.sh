#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./down-one.sh <clientname> [--purge]

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
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

PURGE="false"
if [[ "${MODE}" == "--purge" ]]; then
  PURGE="true"
elif [[ -n "${MODE}" ]]; then
  echo "Usage: $0 <clientname> [--purge]"
  exit 1
fi

CLIENT_DIR="${ROOT_DIR}/clients/${CLIENT}"

echo "==> DOWN-ONE: ${CLIENT} (purge=${PURGE})"

if [[ ! -d "${CLIENT_DIR}" || ! -f "${CLIENT_DIR}/docker-compose.yml" ]]; then
  echo "Client not found: ${CLIENT_DIR}"
  exit 1
fi

if [[ "${PURGE}" == "true" ]]; then
  ( cd "${CLIENT_DIR}" && docker compose down -v )
else
  ( cd "${CLIENT_DIR}" && docker compose down )
fi

echo "✅ Stopped ${CLIENT}"
