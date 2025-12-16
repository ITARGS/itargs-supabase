# itargs-supabase

A **production-ready, self-hosted multi-client Supabase platform** built with **Docker + Caddy**, designed to run **multiple isolated ecommerce projects** on a single server.

Each client gets:

* its **own Supabase stack**
* isolated **Postgres database**
* isolated **Auth users**
* isolated **Storage**
* **Supabase Studio dashboard** for web-based management
* a dedicated API endpoint: `https://api.<client>.itargs.com`
* a dedicated Studio dashboard: `https://studio.<client>.itargs.com`

This repository includes **automation scripts** to safely create, manage, validate, start, stop, and delete clients.

---

## Why this architecture?

* Strong isolation per client (no shared DB, users, or secrets)
* Matches Supabase self-hosted best practices
* Simple Docker Compose operations
* Scales from a few clients to dozens
* No vendor lock-in

Ideal for:

* Agencies hosting multiple ecommerce clients
* SaaS platforms with strict data separation
* Security-sensitive workloads

---

## Architecture Overview

```
Internet
   |
   |  https://api.client.itargs.com
   |  https://studio.client.itargs.com
   v
+--------+
| Caddy  |  (TLS / automatic routing)
+--------+
     |
     v
+-------------------+
| Client Kong (API) |
+-------------------+
     |
     +-> Auth
     +-> PostgREST
     +-> Realtime
     +-> Storage
     +-> Studio (Dashboard)
     +-> Postgres
```

* **Caddy**

  * Automatic HTTPS (Let’s Encrypt)
  * Automatic client routing (no manual config needed)
* **Kong**

  * API gateway per client
* **Supabase services**

  * Fully isolated per client
  * Studio dashboard for web-based management
* **Database**

  * Auto-initialized with roles, schemas, and permissions

---

## Repository Structure

```
itargs-supabase/
├── caddy/
│   ├── docker-compose.yml
│   └── Caddyfile
│
├── clients/
│   └── <client-name>/
│       ├── docker-compose.yml
│       ├── kong.yml
│       └── .env
│
├── tools/
│   ├── create-client.sh
│   └── delete-client.sh
│
├── up.sh
├── down.sh
├── down-all.sh
├── up-one.sh
├── down-one.sh
├── status.sh
├── validate.sh
│
└── README.md
```

---

## Requirements

* Linux server (Ubuntu recommended)
* Docker 24+
* Docker Compose v2
* Public IP address
* DNS control for `itargs.com`
* Ports `80` and `443` open

---

## Quick Start

Start everything:

```bash
./up.sh
```

Stop everything:

```bash
./down.sh
```

Validate setup:

```bash
./validate.sh
```

---

## Client Management

### Create a new client

```bash
./tools/create-client.sh clientname
cd clients/clientname
docker compose up -d

# Wait for database to start, then initialize it
sleep 10
cd ../..
./tools/init-database.sh clientname
```

Creates:

* `clients/clientname/`
* auto-generated URL-safe secrets (JWT, passwords, API keys)
* Supabase stack with all services
* Database initialization (roles, schemas, permissions)
* Caddy routing (automatic)
* Studio dashboard

**You must add DNS:**

```
api.clientname.itargs.com → server IP
studio.clientname.itargs.com → server IP
```

**Access:**
- API: `https://api.clientname.itargs.com`
- Dashboard: `https://studio.clientname.itargs.com`

**Note:** The `init-database.sh` script ensures all database schemas and roles are created before services try to use them.

---

### Start a single client

```bash
./up-one.sh clientname
```

---

### Stop a single client

```bash
./down-one.sh clientname
```

---

### Stop and DELETE a single client (DANGEROUS)

```bash
./down-one.sh clientname --purge
```

Deletes containers and volumes.

---

### Delete a client (safe)

```bash
./tools/delete-client.sh clientname
```

Stops containers and removes Caddy routing
Keeps volumes and files.

---

### Delete a client completely

```bash
./tools/delete-client.sh clientname --purge
```

Deletes:

* containers
* volumes
* client folder
* Caddy routing

⚠️ **Irreversible**

---

## Global Operations

Start all clients + Caddy:

```bash
./up.sh
```

Stop all clients + Caddy:

```bash
./down.sh
```

Stop everything and delete ALL client data:

```bash
./down-all.sh --purge
```

⚠️ **Deletes all databases and storage**

---

## Monitoring & Status

Show status of Caddy and all clients:

```bash
./status.sh
```

---

## Validation

Run pre-deploy checks:

```bash
./validate.sh
```

Checks:

* Docker availability
* Docker daemon health
* Caddy configuration
* Client folder integrity

Does not modify anything.

---

## Features

### Automatic Setup
- ✅ **URL-safe passwords** - No special characters that break database URLs
- ✅ **JWT key generation** - ANON_KEY and SERVICE_ROLE_KEY auto-created
- ✅ **Database initialization** - Roles, schemas, and permissions pre-configured
- ✅ **Automatic Caddy routing** - Routes added/removed automatically

### Services Included
- ✅ **PostgreSQL** - Isolated database per client
- ✅ **GoTrue (Auth)** - User authentication and management
- ✅ **PostgREST** - Auto-generated REST API
- ✅ **Realtime** - WebSocket subscriptions
- ✅ **Storage** - File uploads and management
- ✅ **Studio Dashboard** - Web UI for managing everything
- ✅ **Kong Gateway** - API routing and management

### Management
- ✅ **One-command client creation** - `./tools/create-client.sh name`
- ✅ **One-command deletion** - `./tools/delete-client.sh name`
- ✅ **Bulk operations** - `./up.sh` and `./down.sh` for all clients
- ✅ **Status monitoring** - `./status.sh` shows all services

---

## Security Notes

* Each client has:

  * unique `JWT_SECRET`
  * unique `ANON_KEY`
  * unique `SERVICE_ROLE_KEY`
  * URL-safe passwords (no special characters)
* Never expose `SERVICE_ROLE_KEY` to frontend apps
* Studio dashboard uses SERVICE_ROLE_KEY (admin access only)
* Restrict SSH access
* Use regular backups (recommended daily)

---

## Recommended Workflow

1. Work locally
2. Create clients using scripts
3. Commit to a private Git repository
4. Pull on the server
5. Operate using:

   * `up-one.sh`
   * `down-one.sh`
   * `status.sh`

---

## Tested With

* Ubuntu 22.04
* Docker 24+
* Docker Compose v2
* Caddy v2.8
* Supabase Postgres 15

---

## Future Improvements

* Automated Postgres backups per client
* Per-client resource limits
* Monitoring (Prometheus + Grafana)
* Cloudflare integration
* Unified `manage.sh` CLI
* Kubernetes migration path

---

## Final Notes

This setup is **production-grade**, not a demo.

It prioritizes:

* isolation
* safety
* operational clarity
* long-term maintainability

You are running a real hosting platform — treat it like one.
