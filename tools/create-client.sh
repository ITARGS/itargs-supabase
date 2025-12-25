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

echo "📁 Creating client directory structure..."
mkdir -p "$CLIENT_DIR/data/db" "$CLIENT_DIR/data/storage"
echo "  ✓ Directories created"

echo "🔐 Generating secure credentials..."
POSTGRES_PASSWORD="$(openssl rand -hex 32 | tr -d '\n')"
JWT_SECRET="$(openssl rand -hex 32 | tr -d '\n')"
SECRET_KEY_BASE="$(openssl rand -hex 48 | tr -d '\n')"
DB_ENC_KEY="$(openssl rand -hex 16 | tr -d '\n')"
echo "  ✓ Database password generated"
echo "  ✓ JWT secret generated"
echo "  ✓ Encryption keys generated"

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

echo "🔑 Generating JWT API keys..."
ANON_KEY="$(gen_jwt anon "$JWT_SECRET")"
echo "  ✓ Anon key generated"
SERVICE_ROLE_KEY="$(gen_jwt service_role "$JWT_SECRET")"
echo "  ✓ Service role key generated"

# Generate shared admin credentials (for both Studio and React app)
echo "🎨 Generating admin credentials..."
ADMIN_EMAIL="admin@${CLIENT}.itargs.com"
ADMIN_PASSWORD=$(openssl rand -base64 12 | tr -d '/+=' | head -c 16)
echo "  ✓ Admin credentials generated"

cat > "$CLIENT_DIR/.env" <<EOF
CLIENT=$CLIENT

# Database
POSTGRES_DB=postgres
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$POSTGRES_PASSWORD

JWT_SECRET=$JWT_SECRET
ANON_KEY="$ANON_KEY"
SERVICE_ROLE_KEY="$SERVICE_ROLE_KEY"

# URLs (required by auth)
SITE_URL=https://$CLIENT.itargs.com
GOTRUE_SITE_URL=https://$CLIENT.itargs.com
API_EXTERNAL_URL=https://api.$CLIENT.itargs.com
URI_ALLOW_LIST=https://$CLIENT.itargs.com,https://api.$CLIENT.itargs.com

# Realtime
APP_NAME=supabase-realtime-$CLIENT
RLIMIT_NOFILE=1048576
SECRET_KEY_BASE="$SECRET_KEY_BASE"
DB_ENC_KEY="$DB_ENC_KEY"

# Shared Admin Credentials (for Studio Basic Auth and React App Login)
ADMIN_EMAIL=$ADMIN_EMAIL
ADMIN_PASSWORD=$ADMIN_PASSWORD
STUDIO_USER=admin
STUDIO_PASSWORD=$ADMIN_PASSWORD
EOF

echo "  ✓ Environment file created"

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

-- Create supabase_admin user for postgres-meta
-- Note: postgres-meta will use POSTGRES_USER and POSTGRES_PASSWORD from env
CREATE ROLE IF NOT EXISTS supabase_admin;

-- Create schemas FIRST (before anything tries to use them)
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS storage;
CREATE SCHEMA IF NOT EXISTS realtime;

-- Set schema owners
ALTER SCHEMA auth OWNER TO postgres;
ALTER SCHEMA storage OWNER TO postgres;
ALTER SCHEMA realtime OWNER TO postgres;

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
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Create schema_migrations table for Realtime (fixes crash)
CREATE TABLE IF NOT EXISTS public.schema_migrations (
  version BIGINT PRIMARY KEY,
  inserted_at TIMESTAMP(0) DEFAULT NOW()
);

INITSQL

cat > "$CLIENT_DIR/kong.yml" <<'EOF'
_format_version: "2.1"
_transform: true

plugins:
  - name: cors
    config:
      origins:
        - "*"
      methods:
        - GET
        - POST
        - PUT
        - PATCH
        - DELETE
        - OPTIONS
        - HEAD
      headers:
        - Accept
        - Accept-Encoding
        - Authorization
        - Content-Type
        - apikey
        - x-client-info
        - x-supabase-api-version
        - accept-profile
        - content-profile
        - prefer
        - range
        - x-upsert
        - tus-resumable
        - upload-length
        - upload-metadata
        - upload-offset
        - upload-defer-length
        - x-source
        - cache-control
        - x-requested-with
      exposed_headers:
        - X-Total-Count
        - Content-Range
        - Location
        - Upload-Offset
        - Upload-Length
      credentials: true
      max_age: 3600
      preflight_continue: false

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
      GOTRUE_DB_DATABASE_URL: postgres://\${POSTGRES_USER}:\${POSTGRES_PASSWORD}@db:5432/\${POSTGRES_DB}?sslmode=disable&search_path=auth

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
    image: supabase/storage-api:v1.14.0
    restart: unless-stopped
    env_file: .env
    environment:
      ANON_KEY: \${ANON_KEY}
      SERVICE_KEY: \${SERVICE_ROLE_KEY}
      POSTGREST_URL: http://rest:3000
      PGRST_JWT_SECRET: \${JWT_SECRET}
      DATABASE_URL: postgres://\${POSTGRES_USER}:\${POSTGRES_PASSWORD}@db:5432/\${POSTGRES_DB}?search_path=storage
      FILE_SIZE_LIMIT: 52428800
      STORAGE_BACKEND: file
      FILE_STORAGE_BACKEND_PATH: /var/lib/storage
      TENANT_ID: ${CLIENT}
      GLOBAL_S3_PROTOCOL: https
      STORAGE_API_EXTERNAL_URL: https://api.${CLIENT}.itargs.com/storage/v1
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

  meta:
    image: supabase/postgres-meta:v0.68.0
    restart: unless-stopped
    env_file: .env
    environment:
      PG_META_PORT: 8080
      PG_META_DB_HOST: db
      PG_META_DB_PORT: 5432
      PG_META_DB_NAME: \${POSTGRES_DB}
      PG_META_DB_USER: \${POSTGRES_USER}
      PG_META_DB_PASSWORD: \${POSTGRES_PASSWORD}
    depends_on: [db]
    networks: [${CLIENT}_internal]

  studio:
    image: supabase/studio:latest
    restart: unless-stopped
    env_file: .env
    environment:
      STUDIO_PG_META_URL: http://meta:8080
      
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
      
      # Make Studio listen on all network interfaces
      HOSTNAME: 0.0.0.0
      
      LOGFLARE_API_KEY: your-super-secret-and-long-logflare-key
      LOGFLARE_URL: http://analytics:4000
      NEXT_PUBLIC_ENABLE_LOGS: "false"
      NEXT_ANALYTICS_BACKEND_PROVIDER: postgres
    depends_on: [db, rest, meta]
    networks:
      - ${CLIENT}_internal
      - edge

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
  
  # Check if route already exists
  if grep -q "# Client: $CLIENT" "$CADDYFILE"; then
    echo "Caddy routes for $CLIENT already exist, skipping..."
  else
    # Generate Studio credentials
    STUDIO_USER="admin"
    STUDIO_PASSWORD="$(openssl rand -hex 16)"
    
    # Hash password for Caddy Basic Auth
    STUDIO_PASSWORD_HASH=$(docker run --rm caddy:2.8 caddy hash-password --plaintext "$STUDIO_PASSWORD")
    
    # Save credentials to .env
    echo "" >> "$CLIENT_DIR/.env"
    echo "# Studio Dashboard Credentials" >> "$CLIENT_DIR/.env"
    echo "STUDIO_USER=$STUDIO_USER" >> "$CLIENT_DIR/.env"
    echo "STUDIO_PASSWORD=$STUDIO_PASSWORD" >> "$CLIENT_DIR/.env"
    
    # Add route for this client
    cat >> "$CADDYFILE" <<CADDY

# Client: $CLIENT
api.$CLIENT.itargs.com {
  reverse_proxy ${CLIENT}_kong:8000
}

studio.$CLIENT.itargs.com {
  basicauth {
    $STUDIO_USER $STUDIO_PASSWORD_HASH
  }
  reverse_proxy supabase_${CLIENT}-studio-1:3000
}

CADDY
    
    echo "✅ Caddy routes configured for $CLIENT"
  fi
  
  # Reload Caddy if running
  if docker ps --format '{{.Names}}' | grep -qx 'caddy'; then
    echo "Reloading Caddy..."
    docker exec caddy caddy reload --config /etc/caddy/Caddyfile 2>/dev/null || \
    (cd "$CADDY_DIR" && docker compose restart) || true
  fi
fi

echo "✅ Client created: $CLIENT"
echo ""
echo "Starting containers..."

# Ensure edge network exists
echo "🌐 Checking edge network..."
if docker network inspect edge >/dev/null 2>&1; then
  echo "  ✓ Edge network already exists"
else
  docker network create edge >/dev/null
  echo "  ✓ Edge network created"
fi

# Start the containers
echo "🚀 Starting Docker containers..."
cd "$CLIENT_DIR"
docker compose up -d
echo "  ✓ Containers started"

echo "Waiting for database to be ready..."
# Wait for database to be fully ready (increased from 15 to 30 seconds)
for i in {1..30}; do
  if docker exec "supabase_${CLIENT}-db-1" pg_isready -U postgres >/dev/null 2>&1; then
    echo "Database is ready!"
    break
  fi
  sleep 1
  echo -n "."
done
echo ""

# Additional wait to ensure database is fully initialized
sleep 5

# Stop auth and realtime to prevent race condition during schema creation
echo "Stopping auth and realtime services temporarily..."
docker compose stop auth realtime

# Run database initialization
echo "Initializing database..."
POSTGRES_PASSWORD=$(grep POSTGRES_PASSWORD .env | cut -d= -f2)

# First: Create schemas and roles without password
echo "  - Creating schemas (auth, storage, realtime)..."
if ! docker exec "supabase_${CLIENT}-db-1" psql -U postgres -c "
BEGIN;
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS storage;
CREATE SCHEMA IF NOT EXISTS realtime;
ALTER SCHEMA auth OWNER TO postgres;
ALTER SCHEMA storage OWNER TO postgres;
ALTER SCHEMA realtime OWNER TO postgres;
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'anon') THEN CREATE ROLE anon NOLOGIN NOINHERIT; END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticated') THEN CREATE ROLE authenticated NOLOGIN NOINHERIT; END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'service_role') THEN CREATE ROLE service_role NOLOGIN NOINHERIT BYPASSRLS; END IF;
END \$\$;
GRANT USAGE ON SCHEMA public, auth, realtime TO anon, authenticated, service_role;
GRANT ALL ON SCHEMA storage TO postgres, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public, auth, realtime TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA storage TO postgres, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public, auth, realtime TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA storage TO postgres, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public, auth, storage, realtime TO anon, authenticated, service_role;

-- Force fix for Realtime: Ensure schema_migrations exists with correct columns
CREATE TABLE IF NOT EXISTS public.schema_migrations (
  version BIGINT PRIMARY KEY,
  inserted_at TIMESTAMP(0) DEFAULT NOW()
);
-- If table exists but missing column (e.g. created by older migration)
DO \$\$
BEGIN
  BEGIN
    ALTER TABLE public.schema_migrations ADD COLUMN inserted_at TIMESTAMP(0) DEFAULT NOW();
  EXCEPTION
    WHEN duplicate_column THEN RAISE NOTICE 'column inserted_at already exists in schema_migrations.';
  END;
  
  -- Force version to be BIGINT (Realtime expects integer, but migration create might default to text)
  BEGIN
    ALTER TABLE public.schema_migrations ALTER COLUMN version TYPE BIGINT USING version::BIGINT;
  EXCEPTION
    WHEN OTHERS THEN RAISE NOTICE 'Could not alter version column: %', SQLERRM;
  END;
END \$\$;
-- Realtime needs permission to write to this table if it uses a non-superuser
GRANT ALL ON TABLE public.schema_migrations TO postgres, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon, authenticated, service_role;
COMMIT;
"
then
  echo "❌ ERROR: Failed to create database schemas!"
  echo "Please check database logs: docker logs supabase_${CLIENT}-db-1"
  exit 1
fi
echo "  ✓ Schemas created successfully"

# Second: Create supabase_admin with password (needs variable substitution)
echo "  - Creating supabase_admin role..."
if ! docker exec "supabase_${CLIENT}-db-1" psql -U postgres -c "
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_admin') THEN
    CREATE ROLE supabase_admin LOGIN SUPERUSER CREATEROLE CREATEDB REPLICATION BYPASSRLS PASSWORD '$POSTGRES_PASSWORD';
  ELSE
    ALTER ROLE supabase_admin WITH SUPERUSER;
  END IF;
END \$\$;

GRANT ALL PRIVILEGES ON DATABASE postgres TO supabase_admin;

-- Explicitly grant CREATE and USAGE on schemas
GRANT ALL ON SCHEMA public, auth, storage, realtime TO supabase_admin;

-- Grant permissions on all existing objects
GRANT ALL ON ALL TABLES IN SCHEMA public, auth, storage, realtime TO supabase_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public, auth, storage, realtime TO supabase_admin;

-- Set default privileges for new objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO supabase_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO supabase_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO supabase_admin;

-- Ensure supabase_admin can manage all schemas
ALTER SCHEMA public OWNER TO supabase_admin;
ALTER SCHEMA auth OWNER TO supabase_admin;
ALTER SCHEMA storage OWNER TO supabase_admin;
ALTER SCHEMA realtime OWNER TO supabase_admin;

-- Grant full permissions on auth schema for Studio user management
GRANT ALL ON SCHEMA auth TO postgres, supabase_admin, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA auth TO postgres, supabase_admin, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA auth TO postgres, supabase_admin, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA auth TO postgres, supabase_admin, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA auth GRANT ALL ON TABLES TO postgres, supabase_admin, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA auth GRANT ALL ON SEQUENCES TO postgres, supabase_admin, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA auth GRANT ALL ON FUNCTIONS TO postgres, supabase_admin, service_role;
GRANT USAGE ON SCHEMA auth TO authenticated, anon;

-- Create supabase_migrations schema for Studio migrations UI
CREATE SCHEMA IF NOT EXISTS supabase_migrations;
CREATE TABLE IF NOT EXISTS supabase_migrations.schema_migrations (
  version TEXT PRIMARY KEY,
  statements TEXT[],
  name TEXT,
  inserted_at TIMESTAMPTZ DEFAULT NOW()
);
GRANT USAGE ON SCHEMA supabase_migrations TO postgres, supabase_admin;
GRANT ALL ON ALL TABLES IN SCHEMA supabase_migrations TO postgres, supabase_admin;

-- Full Studio permissions for storage schema
GRANT ALL ON SCHEMA storage TO postgres;
GRANT ALL ON ALL TABLES IN SCHEMA storage TO postgres;
GRANT ALL ON ALL SEQUENCES IN SCHEMA storage TO postgres;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA storage TO postgres;
ALTER DEFAULT PRIVILEGES IN SCHEMA storage GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES IN SCHEMA storage GRANT ALL ON SEQUENCES TO postgres;

-- Full Studio permissions for public schema
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO postgres;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;

-- Full Studio permissions for realtime schema
GRANT ALL ON SCHEMA realtime TO postgres;
GRANT ALL ON ALL TABLES IN SCHEMA realtime TO postgres;
GRANT ALL ON ALL SEQUENCES IN SCHEMA realtime TO postgres;

-- Extensions schema for Studio
CREATE SCHEMA IF NOT EXISTS extensions;
GRANT ALL ON SCHEMA extensions TO postgres;
"
then
  echo "❌ ERROR: Failed to create supabase_admin role!"
  exit 1
fi
echo "  ✓ Database roles and permissions configured"

echo "🔄 Starting auth and realtime services..."
docker compose start auth realtime
echo "  ✓ Services started successfully"

# Wait for storage service to run migrations
echo "⏳ Waiting for storage migrations..."
sleep 10

# Disable RLS on storage tables (Storage API needs direct access)
echo "🔓 Disabling RLS on storage tables..."
docker exec "supabase_${CLIENT}-db-1" psql -U postgres -c "
ALTER TABLE storage.buckets DISABLE ROW LEVEL SECURITY;
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;
ALTER TABLE storage.migrations DISABLE ROW LEVEL SECURITY;
ALTER TABLE storage.s3_multipart_uploads DISABLE ROW LEVEL SECURITY;
ALTER TABLE storage.s3_multipart_uploads_parts DISABLE ROW LEVEL SECURITY;
" 2>/dev/null || echo "  ⚠️  Some storage tables may not exist yet (this is OK)"
echo "  ✓ Storage tables configured"

echo ""
echo "✅ Client is ready!"
echo ""

# Create default admin user
echo "👤 Creating default admin user..."
# ADMIN_EMAIL and ADMIN_PASSWORD are already set at the top of the script

# Wait for auth service to be ready
sleep 5

# Create admin user via GoTrue API
ADMIN_RESPONSE=$(curl -s -X POST "http://localhost:9999/admin/users" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(grep SERVICE_ROLE_KEY .env | cut -d= -f2)" \
  -d "{
    \"email\": \"${ADMIN_EMAIL}\",
    \"password\": \"${ADMIN_PASSWORD}\",
    \"email_confirm\": true,
    \"role\": \"authenticated\"
  }" 2>/dev/null) || true

# Get admin user ID
ADMIN_USER_ID=$(echo "$ADMIN_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -n "$ADMIN_USER_ID" ]; then
  # Create profile and admin role
  docker exec "supabase_${CLIENT}-db-1" psql -U postgres -c "
  -- Create profile
  INSERT INTO public.profiles (id, email, full_name)
  VALUES ('${ADMIN_USER_ID}', '${ADMIN_EMAIL}', 'Admin User')
  ON CONFLICT (id) DO NOTHING;
  
  -- Assign admin role
  INSERT INTO public.user_roles (user_id, role)
  VALUES ('${ADMIN_USER_ID}', 'admin')
  ON CONFLICT (user_id, role) DO NOTHING;
  " 2>/dev/null || true
  echo "  ✓ Admin user created"
else
  echo "  ⚠️  Could not create admin user via API (you can create manually)"
fi

echo ""
echo "🔐 Shared Admin Credentials (for both Studio and React App):"
echo "  Email: ${ADMIN_EMAIL}"
echo "  Password: ${ADMIN_PASSWORD}"
echo ""
echo "Studio Dashboard:"
echo "  URL: https://studio.$CLIENT.itargs.com"
echo "  Username: admin"
echo "  Password: ${ADMIN_PASSWORD}"
echo ""
echo "React App Admin:"
echo "  Email: ${ADMIN_EMAIL}"
echo "  Password: ${ADMIN_PASSWORD}"
echo ""
echo "API Endpoint:"
echo "  https://api.$CLIENT.itargs.com"
echo ""
echo "DNS Setup Required:"
echo "  api.$CLIENT.itargs.com → your server IP"
echo "  studio.$CLIENT.itargs.com → your server IP"

# ============================================
# E-COMMERCE DATABASE SETUP
# ============================================
echo ""
echo "🛒 E-commerce Database Setup"
echo ""
echo "Do you want to set up the complete e-commerce database?"
echo "1) Yes - Complete setup (schema + settings + dummy data)"
echo "2) Yes - Production setup (schema + settings only)"
echo "3) No - Skip e-commerce setup"
read -p "Enter choice [1-3]: " ECOM_SETUP

if [ "$ECOM_SETUP" = "1" ] || [ "$ECOM_SETUP" = "2" ]; then
    DATABASE_SETUP_DIR="$BASE_DIR/database_setup"
    
    if [ ! -d "$DATABASE_SETUP_DIR" ]; then
        echo "⚠️  Database setup directory not found: $DATABASE_SETUP_DIR"
        echo "Skipping e-commerce setup..."
    else
        echo "📦 Running e-commerce database setup..."
        
        # Run schema script
        if [ -f "$DATABASE_SETUP_DIR/01_complete_schema.sql" ]; then
            echo "  - Creating e-commerce schema..."
            if docker exec -i "supabase_${CLIENT}-db-1" psql -U postgres -d postgres < "$DATABASE_SETUP_DIR/01_complete_schema.sql" 2>&1 | grep -q "ERROR"; then
                echo "  ⚠️  Some schema errors occurred (may be normal if tables exist)"
            else
                echo "  ✓ E-commerce schema created"
            fi
        fi
        
        # Run settings script
        if [ -f "$DATABASE_SETUP_DIR/02_initial_settings.sql" ]; then
            echo "  - Populating settings..."
            docker exec -i "supabase_${CLIENT}-db-1" psql -U postgres -d postgres < "$DATABASE_SETUP_DIR/02_initial_settings.sql" > /dev/null 2>&1
            echo "  ✓ Settings populated"
        fi
        
        # Run dummy data if option 1
        if [ "$ECOM_SETUP" = "1" ] && [ -f "$DATABASE_SETUP_DIR/03_dummy_data.sql" ]; then
            echo "  - Loading dummy data..."
            docker exec -i "supabase_${CLIENT}-db-1" psql -U postgres -d postgres < "$DATABASE_SETUP_DIR/03_dummy_data.sql" > /dev/null 2>&1
            echo "  ✓ Dummy data loaded"
        fi
        
        echo ""
        echo "✅ E-commerce database setup complete!"
        echo ""
        echo "📊 Database includes:"
        echo "  - 16 tables (products, orders, reviews, bundles, etc.)"
        echo "  - Payment methods (COD, Vodafone Cash, InstaPay, Cards)"
        echo "  - Shipping methods (Standard, Express, Same Day)"
        echo "  - 5 product categories"
        if [ "$ECOM_SETUP" = "1" ]; then
            echo "  - Sample products and test data"
        fi
        echo ""
        echo "🔧 Next steps:"
        echo "  1. Create storage buckets: product-images, review-images, store-assets"
        echo "  2. Update settings via admin dashboard"
        echo "  3. Upload product images"
    fi
fi

echo ""
