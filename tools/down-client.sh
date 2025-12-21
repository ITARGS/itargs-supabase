#!/bin/bash
set -e

# Down a single client's Docker services
# Usage: ./down-client.sh <client-name> [--volumes]

CLIENT=$1
REMOVE_VOLUMES=$2

if [ -z "$CLIENT" ]; then
    echo "Usage: ./down-client.sh <client-name> [--volumes]"
    echo "  --volumes: Also remove volumes (DATA WILL BE LOST)"
    exit 1
fi

CLIENT_DIR="clients/$CLIENT"

if [ ! -d "$CLIENT_DIR" ]; then
    echo "❌ Client '$CLIENT' not found in $CLIENT_DIR"
    exit 1
fi

cd "$CLIENT_DIR"

echo "🛑 Stopping client: $CLIENT"

if [ "$REMOVE_VOLUMES" = "--volumes" ]; then
    echo "⚠️  Removing volumes (data will be lost)..."
    docker compose down -v
else
    docker compose down
fi

echo "✅ Client '$CLIENT' stopped successfully"
