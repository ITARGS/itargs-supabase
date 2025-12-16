#!/usr/bin/env bash
set -euo pipefail

CLIENT="${1:-}"
if [[ -z "$CLIENT" ]]; then
  echo "Usage: ./tools/init-database.sh <client-name>"
  exit 1
fi

CLIENT="$(echo "$CLIENT" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_-')"
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLIENT_DIR="$BASE_DIR/clients/$CLIENT"

if [[ ! -d "$CLIENT_DIR" ]]; then
  echo "Client not found: $CLIENT"
  exit 1
fi

echo "Initializing database for client: $CLIENT"

# Get the postgres password
POSTGRES_PASSWORD=$(grep POSTGRES_PASSWORD "$CLIENT_DIR/.env" | cut -d= -f2)

# Wait for database to be ready
echo "Waiting for database to be ready..."
sleep 10

# Create all required schemas and roles
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
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon, authenticated, service_role;
EOF

echo "✅ Database initialized successfully"
echo "Restarting services..."

cd "$CLIENT_DIR"
docker compose restart

echo "✅ All services restarted"
