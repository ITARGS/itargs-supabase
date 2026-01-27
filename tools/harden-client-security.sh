#!/usr/bin/env bash
set -euo pipefail

CLIENT="${1:-}"

if [[ -z "$CLIENT" ]]; then
  echo "Usage: ./tools/harden-client-security.sh <client-name>"
  exit 1
fi

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLIENT_DIR="$BASE_DIR/clients/$CLIENT"
HARDEN_SQL="$BASE_DIR/HARDEN-RLS-2026.sql"

if [[ ! -d "$CLIENT_DIR" ]]; then
  echo "❌ Error: Client directory not found: $CLIENT_DIR"
  exit 1
fi

if [[ ! -f "$HARDEN_SQL" ]]; then
  echo "❌ Error: RLS hardening script not found: $HARDEN_SQL"
  exit 1
fi

CONTAINER_NAME="supabase_${CLIENT}-db-1"

# Check if database container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "❌ Error: Database container ${CONTAINER_NAME} is not running."
  exit 1
fi

echo "🛡️ Hardening RLS for client: $CLIENT..."
docker exec -i "${CONTAINER_NAME}" psql -U postgres < "$HARDEN_SQL"

echo "🔒 Enhancing Caddy security headers..."
CADDYFILE="$BASE_DIR/caddy/Caddyfile"

if [[ -f "$CADDYFILE" ]]; then
  # Create a backup
  cp "$CADDYFILE" "${CADDYFILE}.bak"
  
  # Remove existing security headers block if we're re-running
  # (Simpler to just use sed to replace/append)
  
  # We'll use a temporary file to rebuild the Caddyfile with headers
  TEMP_CADDY=$(mktemp)
  
  # Process the Caddyfile and add headers to this client's blocks
  # We look for the client markers we added in create-client.sh
  
  awk -v client="$CLIENT" '
  BEGIN { in_block = 0 }
  $0 ~ "# Client: " client { in_block = 1 }
  in_block && $0 ~ "{" {
    print $0
    print "  header {"
    print "    Strict-Transport-Security \"max-age=31536000; includeSubDomains; preload\""
    print "    X-Content-Type-Options nosniff"
    print "    X-Frame-Options DENY"
    print "    X-XSS-Protection \"1; mode=block\""
    print "    Referrer-Policy \"strict-origin-when-cross-origin\""
    print "    Content-Security-Policy \"default-src '\''self'\''; script-src '\''self'\'' '\''unsafe-inline'\'' https://connect.facebook.net https://analytics.tiktok.com; style-src '\''self'\'' '\''unsafe-inline'\''; img-src '\''self'\'' data: https://*.itargs.com https://*.supabase.co https://*.facebook.com; connect-src '\''self'\'' https://api." client ".itargs.com https://*.supabase.co;\""
    print "  }"
    next
  }
  in_block && $0 ~ "}" { in_block = 0 }
  { print $0 }
  ' "$CADDYFILE" > "$TEMP_CADDY"
  
  mv "$TEMP_CADDY" "$CADDYFILE"
  
  echo "✅ Caddyfile updated with security headers."
  
  # Reload Caddy
  echo "🔄 Reloading Caddy..."
  docker exec caddy caddy reload --config /etc/caddy/Caddyfile 2>/dev/null || echo "⚠️  Failed to reload Caddy automatically."
else
  echo "⚠️  Caddyfile not found. Skipping security header enhancement."
fi

echo "✨ Security hardening complete for $CLIENT!"
