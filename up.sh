#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> UP: starting services"

# Ensure shared edge network exists
docker network inspect edge >/dev/null 2>&1 || docker network create edge >/dev/null

# Start Caddy first (shared reverse proxy)
if [[ -f "$BASE_DIR/caddy/docker-compose.yml" ]]; then
  echo "-> Starting Caddy"
  docker compose -f "$BASE_DIR/caddy/docker-compose.yml" up -d
else
  echo "-> Caddy not found, skipping"
fi

# Start each client
if [[ -d "$BASE_DIR/clients" ]]; then
  for d in "$BASE_DIR/clients"/*; do
    [[ -d "$d" ]] || continue
    [[ -f "$d/docker-compose.yml" ]] || continue
    CLIENT=$(basename "$d")
    echo "-> Starting client: $CLIENT"
    (cd "$d" && docker compose up -d)
    
    # Wait a moment for database to start
    sleep 3
    
    # Check if auth schema exists, if not, initialize database
    if docker exec "supabase_${CLIENT}-db-1" psql -U postgres -tAc "SELECT 1 FROM pg_namespace WHERE nspname='auth'" 2>/dev/null | grep -q 1; then
      echo "   Database already initialized"
    else
      echo "   Initializing database for $CLIENT..."
      POSTGRES_PASSWORD=$(grep POSTGRES_PASSWORD "$d/.env" | cut -d= -f2)
      
      docker exec "supabase_${CLIENT}-db-1" psql -U postgres <<EOF
-- Create schemas
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS storage;
CREATE SCHEMA IF NOT EXISTS realtime;

-- Set owners
ALTER SCHEMA auth OWNER TO postgres;
ALTER SCHEMA storage OWNER TO postgres;
ALTER SCHEMA realtime OWNER TO postgres;

-- Create roles
DO \$\$
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
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_admin') THEN
    CREATE ROLE supabase_admin LOGIN CREATEROLE CREATEDB REPLICATION BYPASSRLS PASSWORD '$POSTGRES_PASSWORD';
  END IF;
END
\$\$;

-- Grant permissions
GRANT USAGE ON SCHEMA public, auth, storage, realtime TO anon, authenticated, service_role, supabase_admin;
GRANT ALL ON ALL TABLES IN SCHEMA public, auth, storage, realtime TO anon, authenticated, service_role, supabase_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public, auth, storage, realtime TO anon, authenticated, service_role, supabase_admin;
GRANT ALL PRIVILEGES ON DATABASE postgres TO supabase_admin;

-- Fix schema_migrations table
ALTER TABLE public.schema_migrations ADD COLUMN IF NOT EXISTS inserted_at TIMESTAMP DEFAULT NOW();

-- Set default privileges
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role, supabase_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role, supabase_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon, authenticated, service_role, supabase_admin;
EOF
      
      echo "   Restarting services for $CLIENT..."
      (cd "$d" && docker compose restart)
    fi
  done
else
  echo "-> No clients directory, skipping"
fi

