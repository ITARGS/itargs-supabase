#!/usr/bin/env bash
set -euo pipefail

CLIENT="${1:-}"

if [[ -z "$CLIENT" ]]; then
  echo "Usage: ./tools/create-client.sh <client-name>"
  exit 1
fi

# normalize client name (lowercase, no spaces)
CLIENT="$(echo "$CLIENT" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_-')"
if [[ -z "$CLIENT" ]]; then
  echo "Invalid client name."
  exit 1
fi

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLIENT_DIR="$BASE_DIR/clients/$CLIENT"

if [[ -d "$CLIENT_DIR" ]]; then
  echo "Client already exists: $CLIENT"
  exit 1
fi

mkdir -p "$CLIENT_DIR/data/db" "$CLIENT_DIR/data/storage"

POSTGRES_PASSWORD="$(openssl rand -hex 32 | tr -d '\n')"
JWT_SECRET="$(openssl rand -hex 32 | tr -d '\n')"
SECRET_KEY_BASE="$(openssl rand -hex 48 | tr -d '\n')"
DB_ENC_KEY="$(openssl rand -hex 16 | tr -d '\n')"

# Generate JWT tokens for API access
gen_jwt() {
  local role="$1"
  local secret="$2"
  docker run --rm node:20-alpine node -e "
    const crypto = require('crypto');
    const header = Buffer.from(JSON.stringify({alg:'HS256',typ:'JWT'})).toString('base64url');
    const payload = Buffer.from(JSON.stringify({
      iss:'supabase',
      aud:'authenticated',
      role:'$role',
      iat:Math.floor(Date.now()/1000),
      exp:Math.floor(Date.now()/1000)+315360000
    })).toString('base64url');
    const sig = crypto.createHmac('sha256','$secret').update(header+'.'+payload).digest('base64url');
    console.log(header+'.'+payload+'.'+sig);
  "
}

echo "Generating JWT keys..."
ANON_KEY="$(gen_jwt anon "$JWT_SECRET")"
SERVICE_ROLE_KEY="$(gen_jwt service_role "$JWT_SECRET")"

cat > "$CLIENT_DIR/.env" <<EOF
CLIENT=$CLIENT

POSTGRES_DB=postgres
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$POSTGRES_PASSWORD

JWT_SECRET=$JWT_SECRET
ANON_KEY=$ANON_KEY
SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY

# URLs (required by auth)
SITE_URL=https://$CLIENT.itargs.com
GOTRUE_SITE_URL=https://$CLIENT.itargs.com
API_EXTERNAL_URL=https://api.$CLIENT.itargs.com
URI_ALLOW_LIST=https://$CLIENT.itargs.com,https://api.$CLIENT.itargs.com

# Realtime
APP_NAME=supabase-realtime-$CLIENT
RLIMIT_NOFILE=1048576
SECRET_KEY_BASE=$SECRET_KEY_BASE
DB_ENC_KEY=$DB_ENC_KEY
EOF

# Create database initialization script
cat > "$CLIENT_DIR/init.sql" <<'INITSQL'
-- Create required roles for Supabase
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'anon') THEN
    CREATE ROLE anon NOLOGIN NOINHERIT;
  END IF;
  
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticated') THEN
    CREATE ROLE authenticated NOLOGIN NOINHERIT;
  END IF;
  
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'service_role') THEN
    CREATE ROLE service_role NOLOGIN NOINHERIT BYPASSRLS;
  END IF;
END
$$;

-- Grant postgres role to service roles
GRANT anon TO postgres;
GRANT authenticated TO postgres;
GRANT service_role TO postgres;

-- Create schemas
CREATE SCHEMA IF NOT EXISTS auth AUTHORIZATION postgres;
CREATE SCHEMA IF NOT EXISTS storage AUTHORIZATION postgres;
CREATE SCHEMA IF NOT EXISTS realtime AUTHORIZATION postgres;

-- Grant schema usage
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT USAGE ON SCHEMA auth TO anon, authenticated, service_role;
GRANT USAGE ON SCHEMA storage TO anon, authenticated, service_role;
GRANT USAGE ON SCHEMA realtime TO anon, authenticated, service_role;

-- Grant table permissions on public schema
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated, service_role;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon, authenticated, service_role;

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create schema_migrations table with inserted_at column for Realtime compatibility
CREATE TABLE IF NOT EXISTS public.schema_migrations (
  version TEXT PRIMARY KEY,
  inserted_at TIMESTAMP DEFAULT NOW()
);

INITSQL

cat > "$CLIENT_DIR/kong.yml" <<'EOF'
_format_version: "2.1"
_transform: true

services:
  - name: rest
    url: http://rest:3000
    routes:
      - name: rest
        paths:
          - /rest/v1
  - name: auth
    url: http://auth:9999
    routes:
      - name: auth
        paths:
          - /auth/v1
  - name: realtime
    url: http://realtime:4000
    routes:
      - name: realtime
        paths:
          - /realtime/v1
  - name: storage
    url: http://storage:5000
    routes:
      - name: storage
        paths:
          - /storage/v1
  - name: studio
    url: http://studio:3000
    routes:
      - name: studio
        paths:
          - /
        strip_path: false
EOF

cat > "$CLIENT_DIR/docker-compose.yml" <<EOF
name: supabase_${CLIENT}

services:
  db:
    image: supabase/postgres:15.1.0.147
    restart: unless-stopped
    env_file: .env
    volumes:
      - ./data/db:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    networks: [${CLIENT}_internal]

  auth:
    image: supabase/gotrue:v2.151.0
    restart: unless-stopped
    env_file: .env
    environment:
      GOTRUE_API_HOST: 0.0.0.0
      GOTRUE_API_PORT: 9999

      SITE_URL: \${SITE_URL}
      GOTRUE_SITE_URL: \${GOTRUE_SITE_URL}
      API_EXTERNAL_URL: \${API_EXTERNAL_URL}
      GOTRUE_URI_ALLOW_LIST: \${URI_ALLOW_LIST}

      GOTRUE_DB_DRIVER: postgres
      GOTRUE_DB_DATABASE_URL: postgres://\${POSTGRES_USER}:\${POSTGRES_PASSWORD}@db:5432/\${POSTGRES_DB}?sslmode=disable

      GOTRUE_JWT_SECRET: \${JWT_SECRET}
      GOTRUE_JWT_AUD: authenticated
      GOTRUE_JWT_EXP: 3600

      GOTRUE_MAILER_AUTOCONFIRM: "true"
      GOTRUE_SMS_AUTOCONFIRM: "true"
      GOTRUE_DISABLE_SIGNUP: "false"
    depends_on: [db]
    networks: [${CLIENT}_internal]

  rest:
    image: postgrest/postgrest:v12.2.0
    restart: unless-stopped
    env_file: .env
    environment:
      PGRST_DB_URI: postgres://\${POSTGRES_USER}:\${POSTGRES_PASSWORD}@db:5432/\${POSTGRES_DB}
      PGRST_DB_SCHEMA: public
      PGRST_DB_ANON_ROLE: anon
      PGRST_JWT_SECRET: \${JWT_SECRET}
    depends_on: [db]
    networks: [${CLIENT}_internal]

  storage:
    image: supabase/storage-api:v1.11.13
    restart: unless-stopped
    env_file: .env
    environment:
      ANON_KEY: \${ANON_KEY}
      SERVICE_KEY: \${SERVICE_ROLE_KEY}
      POSTGREST_URL: http://rest:3000
      PGRST_JWT_SECRET: \${JWT_SECRET}
      DATABASE_URL: postgres://\${POSTGRES_USER}:\${POSTGRES_PASSWORD}@db:5432/\${POSTGRES_DB}
      FILE_SIZE_LIMIT: 52428800
      STORAGE_BACKEND: file
      FILE_STORAGE_BACKEND_PATH: /var/lib/storage
      TENANT_ID: ${CLIENT}
    volumes:
      - ./data/storage:/var/lib/storage
    depends_on: [db, rest]
    networks: [${CLIENT}_internal]

  realtime:
    image: supabase/realtime:v2.32.5
    restart: unless-stopped
    env_file: .env
    environment:
      PORT: 4000
      APP_NAME: \${APP_NAME}

      DB_HOST: db
      DB_PORT: 5432
      DB_NAME: \${POSTGRES_DB}
      DB_USER: \${POSTGRES_USER}
      DB_PASSWORD: \${POSTGRES_PASSWORD}

      JWT_SECRET: \${JWT_SECRET}
      SECRET_KEY_BASE: \${SECRET_KEY_BASE}
      DB_ENC_KEY: \${DB_ENC_KEY}

      # FIX: avoid conflict with public.schema_migrations
      DB_MIGRATIONS_TABLE: realtime_schema_migrations
      ECTO_MIGRATIONS_TABLE: realtime_schema_migrations

      RLIMIT_NOFILE: \${RLIMIT_NOFILE}
    depends_on: [db]
    networks: [${CLIENT}_internal]

  studio:
    image: supabase/studio:latest
    restart: unless-stopped
    env_file: .env
    environment:
      STUDIO_PG_META_URL: http://rest:3000
      
      SUPABASE_URL: https://api.${CLIENT}.itargs.com
      SUPABASE_PUBLIC_URL: https://api.${CLIENT}.itargs.com
      SUPABASE_ANON_KEY: \${ANON_KEY}
      SUPABASE_SERVICE_KEY: \${SERVICE_ROLE_KEY}
      
      # Direct database connection for Studio
      POSTGRES_HOST: db
      POSTGRES_PORT: 5432
      POSTGRES_DB: \${POSTGRES_DB}
      POSTGRES_USER: \${POSTGRES_USER}
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD}
      
      LOGFLARE_API_KEY: your-super-secret-and-long-logflare-key
      LOGFLARE_URL: http://analytics:4000
      NEXT_PUBLIC_ENABLE_LOGS: "true"
      NEXT_ANALYTICS_BACKEND_PROVIDER: postgres
    depends_on: [db, rest]
    networks: [${CLIENT}_internal]

  kong:
    image: kong:2.8
    container_name: ${CLIENT}_kong
    restart: unless-stopped
    environment:
      KONG_DATABASE: "off"
      KONG_DECLARATIVE_CONFIG: /kong/kong.yml
      KONG_PROXY_LISTEN: "0.0.0.0:8000"
      KONG_ADMIN_LISTEN: "0.0.0.0:8001"
    volumes:
      - ./kong.yml:/kong/kong.yml:ro
    depends_on: [auth, rest, realtime, storage]
    networks:
      - ${CLIENT}_internal
      - edge

networks:
  ${CLIENT}_internal:
    driver: bridge
  edge:
    external: true
    name: edge
EOF

# Add Caddy routing
CADDY_DIR="$BASE_DIR/caddy"
CADDYFILE="$CADDY_DIR/Caddyfile"

if [[ -f "$CADDYFILE" ]]; then
  echo "Adding Caddy routes..."
  
  # Add route for this client
  cat >> "$CADDYFILE" <<CADDY

# Client: $CLIENT
api.$CLIENT.itargs.com {
  reverse_proxy ${CLIENT}_kong:8000
}

studio.$CLIENT.itargs.com {
  reverse_proxy ${CLIENT}_kong:8000
}

CADDY
  
  # Reload Caddy if running
  if docker ps --format '{{.Names}}' | grep -qx 'caddy'; then
    echo "Reloading Caddy..."
    docker exec caddy caddy reload --config /etc/caddy/Caddyfile 2>/dev/null || \
    (cd "$CADDY_DIR" && docker compose restart) || true
  fi
fi

echo "✅ Client created: $CLIENT"
echo "Next:"
echo "  cd clients/$CLIENT"
echo "  docker compose up -d"

