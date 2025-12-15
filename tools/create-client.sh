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

POSTGRES_PASSWORD="$(openssl rand -base64 24 | tr -d '\n')"
JWT_SECRET="$(openssl rand -hex 32 | tr -d '\n')"
SECRET_KEY_BASE="$(openssl rand -base64 48 | tr -d '\n')"
DB_ENC_KEY="$(openssl rand -hex 16 | tr -d '\n')"

cat > "$CLIENT_DIR/.env" <<EOF
CLIENT=$CLIENT

POSTGRES_DB=postgres
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$POSTGRES_PASSWORD

JWT_SECRET=$JWT_SECRET

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
      DATABASE_URL: postgres://\${POSTGRES_USER}:\${POSTGRES_PASSWORD}@db:5432/\${POSTGRES_DB}
      PGRST_JWT_SECRET: \${JWT_SECRET}
    volumes:
      - ./data/storage:/var/lib/storage
    depends_on: [db]
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
      ECTO_MIGRATIONS_TABLE: realtime_schema_migrations

      RLIMIT_NOFILE: \${RLIMIT_NOFILE}
    depends_on: [db]
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
EOF

echo "✅ Client created: $CLIENT"
echo "Next:"
echo "  cd clients/$CLIENT"
echo "  docker compose up -d"
