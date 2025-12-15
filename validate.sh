#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLIENTS_ROOT="${ROOT_DIR}/clients"
CADDY_DIR="${ROOT_DIR}/caddy"
CADDYFILE="${CADDY_DIR}/Caddyfile"

echo "==> VALIDATE"

# Docker check
if ! command -v docker >/dev/null 2>&1; then
  echo "❌ docker not found"
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  echo "❌ docker daemon not reachable (is Docker running?)"
  exit 1
fi
echo "✅ docker OK"

# Caddy checks
if [[ -d "${CADDY_DIR}" && -f "${CADDY_DIR}/docker-compose.yml" ]]; then
  echo "✅ caddy compose found"
  if [[ -f "${CADDYFILE}" ]]; then
    echo "✅ Caddyfile found"
  else
    echo "⚠️  Caddyfile missing: ${CADDYFILE}"
  fi
else
  echo "⚠️  caddy not found (ok if you don't use it)"
fi

# Client checks
if [[ ! -d "${CLIENTS_ROOT}" ]]; then
  echo "⚠️  clients directory missing: ${CLIENTS_ROOT}"
  exit 0
fi

shopt -s nullglob
CLIENT_DIRS=( "${CLIENTS_ROOT}"/* )

VALID=0
BROKEN=0

for d in "${CLIENT_DIRS[@]}"; do
  [[ -d "$d" ]] || continue
  name="$(basename "$d")"

  if [[ -f "$d/docker-compose.yml" && -f "$d/.env" && -f "$d/kong.yml" ]]; then
    VALID=$((VALID+1))
  else
    BROKEN=$((BROKEN+1))
    echo "⚠️  client '${name}' is missing one of: docker-compose.yml, .env, kong.yml"
  fi
done

echo "✅ clients valid: ${VALID}"
if (( BROKEN > 0 )); then
  echo "⚠️  clients broken: ${BROKEN}"
fi

echo "==> VALIDATE done"
