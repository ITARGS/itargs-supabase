#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./tools/create-client.sh <clientname>
# Example:
#   ./tools/create-client.sh saknk

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLIENT="${1:-}"

if [[ -z "${CLIENT}" ]]; then
  echo "Usage: $0 <clientname>"
  exit 1
fi

# safe names only
if ! [[ "${CLIENT}" =~ ^[a-z0-9-]+$ ]]; then
  echo "Client name must match: ^[a-z0-9-]+$"
  exit 1
fi

CLIENT_DIR="${ROOT_DIR}/clients/${CLIENT}"
CADDY_DIR="${ROOT_DIR}/caddy"
CADDYFILE="${CADDY_DIR}/Caddyfile"

DOMAIN_API="api.${CLIENT}.itargs.com"
DOMAIN_SITE="https://${CLIENT}.itargs.com"

if [[ -d "${CLIENT_DIR}" ]]; then
  echo "Client already exists: ${CLIENT_DIR}"
  exit 1
fi

mkdir -p "${CLIENT_DIR}"

# Generate secrets
POSTGRES_PASSWORD="$(openssl rand -base64 24 | tr -d '\n')"
JWT_SECRET="$(openssl rand -hex 32 | tr -d '\n')"

# Generate JWTs signed with JWT_SECRET using a temporary node container
gen_jwt () {
  local role="$1"
  docker run --rm \
    -e JWT_SECRET="${JWT_SECRET}" \
    -e ROLE="${role}" \
    node:20-alpine sh -lc "
      node -e '
        const crypto = require(\"crypto\");
        const b64url = (v) => Buffer.from(v).toString(\"base64\")
          .replace(/=/g, \"\").replace(/\\+/g, \"-\").replace(/\\//g, \"_\");
        const header = b64url(JSON.stringify({alg:\"HS256\",typ:\"JWT\"}));
        const now = Math.floor(Date.now()/1000);
        const payload = b64url(JSON.stringify({
          iss:\"supabase\",
          aud:\"authenticated\",
          role: process.env.ROLE,
          iat: now,
          exp: now + 10*365*24*60*60
        }));
        const data = header + \".\" + payload;
        const sig = crypto.createHmac(\"sha256\", process.env.JWT_SECRET).update(data)
          .digest(\"base64\").replace(/=/g, \"\").replace(/\\+/g, \"-\").replace(/\\//g, \"_\");
        process.stdout.write(data + \".\" + sig);
      '
    "
}

ANON_KEY="$(gen_jwt anon)"
SERVICE_ROLE_KEY="$(gen_jwt service_role)"

# kong.yml
cat > "${CLIENT_DIR}/kong.yml" <<'YAML'
_format_version: "2.1"
_transform: true

services:
  - name: auth
    url: http://auth:9999
    routes:
      - paths: ["/auth/v1"]

  - name: rest
    url: http://rest:3000
    routes:
      - paths: ["/rest/v1"]

  - name: realtime
    url: http://realtime:4000
    routes:
      - paths: ["/realtime/v1"]

  - name: storage
    url: http://storage:5000
    routes:
      - paths: ["/storage/v1"]
YAML

# .env  (includes API_EXTERNAL_URL fix)
cat > "${CLIENT_DIR}/.env" <<ENV
POSTGRES_DB=postgres
POSTGRES_USER=postgres
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

JWT_SECRET=${JWT_SECRET}
ANON_KEY=${ANON_KEY}
SERVICE_ROLE_KEY=${SERVICE_ROLE_KEY}

# Public URLs
SITE_URL=${DOMAIN_SITE}
API_EXTERNAL_URL=https://${DOMAIN_API}
URI_ALLOW_LIST=${DOMAIN_SITE},https://${DOMAIN_API}
ENV

# docker-compose.yml (includes API_EXTERNAL_URL passed into auth)
cat > "${CLIENT_DIR}/docker-compose.yml" <<YAML
name: supabase_${CLIENT}

services:
  db:
    image: supabase/postgres:15.1.0.147
    restart: unless-stopped
    environment:
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD}
      POSTGRES_DB: \${POSTGRES_DB}
      POSTGRES_USER: \${POSTGRES_USER}
    volumes:
      - ${CLIENT}_db_data:/var/lib/postgresql/data
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
    networks:
      - ${CLIENT}_internal
      - edge

  auth:
    image: supabase/gotrue:v2.151.0
    restart: unless-stopped
    environment:
      GOTRUE_API_HOST: 0.0.0.0
      GOTRUE_API_PORT: 9999

      SITE_URL: \${SITE_URL}
      API_EXTERNAL_URL: \${API_EXTERNAL_URL}
      GOTRUE_URI_ALLOW_LIST: \${URI_ALLOW_LIST}

      GOTRUE_DB_DRIVER: postgres
      GOTRUE_DB_DATABASE_URL: postgres://\${POSTGRES_USER}:\${POSTGRES_PASSWORD}@db:5432/\${POSTGRES_DB}?sslmode=disable

      GOTRUE_JWT_SECRET: \${JWT_SECRET}
      GOTRUE_JWT_EXP: 3600
      GOTRUE_JWT_AUD: authenticated
      GOTRUE_DISABLE_SIGNUP: "false"
    depends_on: [db]
    networks: [${CLIENT}_internal]

  rest:
    image: postgrest/postgrest:v12.2.0
    restart: unless-stopped
    environment:
      PGRST_DB_URI: postgres://\${POSTGRES_USER}:\${POSTGRES_PASSWORD}@db:5432/\${POSTGRES_DB}
      PGRST_DB_ANON_ROLE: anon
      PGRST_JWT_SECRET: \${JWT_SECRET}
    depends_on: [db]
    networks: [${CLIENT}_internal]

  realtime:
    image: supabase/realtime:v2.32.5
    restart: unless-stopped
    environment:
      PORT: 4000
      DB_HOST: db
      DB_PORT: 5432
      DB_USER: \${POSTGRES_USER}
      DB_PASSWORD: \${POSTGRES_PASSWORD}
      DB_NAME: \${POSTGRES_DB}
      JWT_SECRET: \${JWT_SECRET}
    depends_on: [db]
    networks: [${CLIENT}_internal]

  storage:
    image: supabase/storage-api:v1.11.13
    restart: unless-stopped
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
      - ${CLIENT}_storage_data:/var/lib/storage
    depends_on: [db, rest]
    networks: [${CLIENT}_internal]

networks:
  edge:
    external: true
    name: edge
  ${CLIENT}_internal:
    name: ${CLIENT}_internal

volumes:
  ${CLIENT}_db_data:
  ${CLIENT}_storage_data:
YAML

# Update Caddyfile with markers (safe delete)
BEGIN="# BEGIN CLIENT ${CLIENT}"
END="# END CLIENT ${CLIENT}"

if [[ -d "${CADDY_DIR}" && -f "${CADDYFILE}" ]]; then
  if grep -qF "${BEGIN}" "${CADDYFILE}"; then
    echo "Caddyfile already has block for ${CLIENT}, skipping append."
  else
    cp "${CADDYFILE}" "${CADDYFILE}.bak.$(date +%Y%m%d-%H%M%S)"
    cat >> "${CADDYFILE}" <<CADDY

${BEGIN}
api.${CLIENT}.itargs.com {
  reverse_proxy ${CLIENT}_kong:8000
}
${END}
CADDY
    echo "Added route to Caddyfile for api.${CLIENT}.itargs.com"
  fi

  # Reload Caddy if container exists, otherwise skip
  if docker ps --format '{{.Names}}' | grep -qx 'caddy'; then
    ( cd "${CADDY_DIR}" && docker compose exec -T caddy caddy reload --config /etc/caddy/Caddyfile ) \
      || ( cd "${CADDY_DIR}" && docker compose restart ) || true
  fi
else
  echo "Caddy not found (caddy/Caddyfile missing). Skipping Caddy update."
fi

echo
echo "✅ Created client: ${CLIENT}"
echo "Client folder: ${CLIENT_DIR}"
echo "API: https://${DOMAIN_API}"
echo
echo "Next steps:"
echo "1) DNS: Create A record ${DOMAIN_API} -> your server IP"
echo "2) Start stack: cd ${CLIENT_DIR} && docker compose up -d"
