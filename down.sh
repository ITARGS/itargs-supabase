#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "Stopping client stacks..."
( cd clients/teststore && docker compose down )
( cd clients/kat && docker compose down )
( cd clients/elnagar && docker compose down )

echo "Stopping Caddy..."
( cd caddy && docker compose down )

echo "Done."
