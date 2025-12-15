#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "Starting Caddy..."
( cd caddy && docker compose up -d )

echo "Starting client stacks..."
( cd clients/elnagar && docker compose up -d )
( cd clients/kat && docker compose up -d )
( cd clients/teststore && docker compose up -d )

echo "Done."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
