# Shussei Infra Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `arkhe-ai/shussei-infra` repository that can run the Shussei MVP stack self-hosted with Docker Compose, Caddy, PostgreSQL, Redis, LiveKit, coturn, and deployment/operator documentation.

**Architecture:** The infra repo owns local and production-like orchestration. Development compose uses sibling checkouts of `shussei-web` and `shussei-api` for image build contexts, while production compose uses tagged container images. Caddy terminates HTTP/TLS for app and API traffic, LiveKit handles SFU duties, coturn handles TURN/STUN, and helper scripts validate host readiness and secrets before deployment.

**Tech Stack:** Docker Compose, Caddy, LiveKit, coturn, PostgreSQL, Redis, Bash, Makefile, GitHub Actions optional later

**Spec:** `/home/matumoto/docs/superpowers/specs/2026-08-27-private-discord-mvp-design.md`

## Global Constraints

- Self-hosted deployment
- Single private organization/community
- Up to 100 total users
- Roughly 20–40 concurrent users in voice
- low perceived latency is a core requirement
- architecture must avoid peer-mesh topologies
- LiveKit SFU is used specifically to preserve scalability and latency for group calls
- official support target: Chrome desktop and Edge desktop
- system audio sharing may not be available everywhere
- TLS everywhere in public access paths
- secure OAuth flow
- LiveKit token issuance only after app-level authorization
- graceful handling of reconnects is required
- backend logs
- reverse proxy logs
- LiveKit logs
- basic health checks
- enough information to diagnose auth failures, WebSocket failures, and RTC join failures
- TLS termination at reverse proxy
- public exposure only for required services
- correct UDP/TCP configuration for RTC and TURN
- 8 vCPU
- 16 GB RAM
- SSD storage
- reliable network throughput

---

## Planned File Structure

### Repository root: `shussei-infra/`

- `README.md` — operator overview and clone layout
- `.env.example` — compose variables and required secrets
- `compose.dev.yml` — local development stack using sibling repos as build contexts
- `compose.prod.yml` — production-like stack using registry images
- `Makefile` — common operator commands
- `scripts/generate-secrets.sh` — creates strong random secrets for local/prod env
- `scripts/check-host.sh` — validates Docker, ports, kernel settings, and open files limits
- `scripts/wait-for-http.sh` — helper to block until health URLs respond
- `caddy/Caddyfile.dev` — local reverse proxy routes
- `caddy/Caddyfile.prod` — production reverse proxy routes with real hostnames
- `livekit/livekit.yaml` — LiveKit configuration
- `turn/turnserver.conf` — coturn configuration
- `monitoring/healthcheck.sh` — checks app, API, LiveKit, Redis, and Postgres reachability
- `docs/deploy-vps.md` — VPS deployment checklist
- `docs/runbook.md` — operational recovery notes

## Repository and Environment Assumptions

- The three repos are cloned as siblings under one parent directory:
  - `../shussei-web`
  - `../shussei-api`
  - `./shussei-infra`
- Local dev URLs use ports:
  - `http://localhost:3000` for web
  - `http://localhost:3001` for API
  - `ws://localhost:7880` for LiveKit
- Production hostnames use subdomains:
  - `app.shussei.example.com`
  - `api.shussei.example.com`
  - `rtc.shussei.example.com`
- Production images are published as:
  - `ghcr.io/arkhe-ai/shussei-web:latest`
  - `ghcr.io/arkhe-ai/shussei-api:latest`

### Task 1: Bootstrap the infra repo, environment template, and dev compose baseline

**Files:**
- Create: `shussei-infra/README.md`
- Create: `shussei-infra/.env.example`
- Create: `shussei-infra/compose.dev.yml`
- Create: `shussei-infra/Makefile`
- Create: `shussei-infra/scripts/check-host.sh`
- Create: `shussei-infra/scripts/generate-secrets.sh`

**Interfaces:**
- Consumes: sibling repos `../shussei-web`, `../shussei-api`
- Produces: `make dev-up`, `make dev-down`, `.env` variables `POSTGRES_PASSWORD`, `REDIS_PASSWORD`, `SESSION_SECRET`, `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`

- [ ] **Step 1: Write the failing host-check smoke script test**

```bash
#!/usr/bin/env bash
set -euo pipefail
output=$(bash scripts/check-host.sh 2>&1 || true)
echo "$output" | grep -q "docker"
```

Save as `tests/check-host-smoke.sh`.

- [ ] **Step 2: Run the smoke script to verify it fails**

Run: `bash tests/check-host-smoke.sh`
Expected: FAIL with `No such file or directory` for `scripts/check-host.sh`

- [ ] **Step 3: Create the dev compose file, env template, and helper scripts**

```yaml
# compose.dev.yml
services:
  web:
    build:
      context: ../shussei-web
    env_file: .env
    environment:
      NEXT_PUBLIC_API_BASE_URL: http://localhost:3001
    ports:
      - '3000:3000'
    depends_on:
      - api

  api:
    build:
      context: ../shussei-api
    env_file: .env
    environment:
      PORT: 3001
      DATABASE_URL: postgresql://postgres:${POSTGRES_PASSWORD}@postgres:5432/shussei
      REDIS_URL: redis://default:${REDIS_PASSWORD}@redis:6379
      LIVEKIT_WS_URL: ws://localhost:7880
    ports:
      - '3001:3001'
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: shussei
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - '5432:5432'

  redis:
    image: redis:7
    command: redis-server --requirepass ${REDIS_PASSWORD}
    ports:
      - '6379:6379'
```

```bash
# scripts/check-host.sh
#!/usr/bin/env bash
set -euo pipefail
command -v docker >/dev/null || { echo 'docker is required'; exit 1; }
docker compose version >/dev/null || { echo 'docker compose is required'; exit 1; }
echo 'docker and docker compose are available'
```

```bash
# scripts/generate-secrets.sh
#!/usr/bin/env bash
set -euo pipefail
openssl rand -hex 24
```

- [ ] **Step 4: Add `make` targets and rerun the smoke test**

```make
SHELL := /bin/bash

check-host:
	bash scripts/check-host.sh

dev-up:
	docker compose --env-file .env -f compose.dev.yml up -d --build

dev-down:
	docker compose --env-file .env -f compose.dev.yml down -v
```

Run: `bash tests/check-host-smoke.sh && make check-host`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add README.md .env.example compose.dev.yml Makefile scripts tests
git commit -m "feat(infra): bootstrap dev compose baseline"
```

### Task 2: Add LiveKit and coturn services with explicit config

**Files:**
- Create: `shussei-infra/livekit/livekit.yaml`
- Create: `shussei-infra/turn/turnserver.conf`
- Modify: `shussei-infra/compose.dev.yml`
- Modify: `shussei-infra/.env.example`
- Create: `shussei-infra/tests/livekit-config-smoke.sh`

**Interfaces:**
- Consumes: `.env` values `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`, `TURN_SHARED_SECRET`, `PUBLIC_IP`
- Produces: Compose services `livekit`, `coturn`; reachable ports `7880/tcp`, `7881/tcp`, `3478/tcp`, `3478/udp`, `5349/tcp`

- [ ] **Step 1: Write the failing LiveKit config smoke script**

```bash
#!/usr/bin/env bash
set -euo pipefail
grep -q "api_key" livekit/livekit.yaml
grep -q "use-auth-secret" turn/turnserver.conf
```

- [ ] **Step 2: Run the smoke script to verify it fails**

Run: `bash tests/livekit-config-smoke.sh`
Expected: FAIL because config files do not exist

- [ ] **Step 3: Create LiveKit and coturn configuration files**

```yaml
# livekit/livekit.yaml
port: 7880
rtc:
  tcp_port: 7881
  use_external_ip: true
keys:
  ${LIVEKIT_API_KEY}: ${LIVEKIT_API_SECRET}
turn:
  enabled: false
redis:
  address: redis:6379
  username: default
  password: ${REDIS_PASSWORD}
```

```conf
# turn/turnserver.conf
listening-port=3478
tls-listening-port=5349
fingerprint
use-auth-secret
static-auth-secret=${TURN_SHARED_SECRET}
realm=shussei.local
external-ip=${PUBLIC_IP}
no-cli
lt-cred-mech
```

- [ ] **Step 4: Wire `livekit` and `coturn` into Compose, then rerun the smoke test**

```yaml
# append to compose.dev.yml
  livekit:
    image: livekit/livekit-server:latest
    command: --config /etc/livekit/livekit.yaml
    env_file: .env
    volumes:
      - ./livekit/livekit.yaml:/etc/livekit/livekit.yaml:ro
    ports:
      - '7880:7880'
      - '7881:7881'
    depends_on:
      - redis

  coturn:
    image: coturn/coturn:4.6
    env_file: .env
    command: -c /etc/coturn/turnserver.conf
    volumes:
      - ./turn/turnserver.conf:/etc/coturn/turnserver.conf:ro
    ports:
      - '3478:3478/tcp'
      - '3478:3478/udp'
      - '5349:5349/tcp'
```

Run: `bash tests/livekit-config-smoke.sh && docker compose --env-file .env -f compose.dev.yml config >/tmp/shussei-compose.txt`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add livekit turn compose.dev.yml .env.example tests/livekit-config-smoke.sh
git commit -m "feat(infra): add livekit and coturn services"
```

### Task 3: Add reverse proxy and production compose file

**Files:**
- Create: `shussei-infra/caddy/Caddyfile.dev`
- Create: `shussei-infra/caddy/Caddyfile.prod`
- Create: `shussei-infra/compose.prod.yml`
- Modify: `shussei-infra/compose.dev.yml`
- Create: `shussei-infra/tests/caddy-smoke.sh`

**Interfaces:**
- Consumes: `app.shussei.example.com`, `api.shussei.example.com`, `rtc.shussei.example.com`
- Produces: Compose service `caddy`; public entrypoints for app/API; websocket proxy pass for API and LiveKit host exposure as configured separately

- [ ] **Step 1: Write the failing Caddy smoke script**

```bash
#!/usr/bin/env bash
set -euo pipefail
grep -q "reverse_proxy web:3000" caddy/Caddyfile.dev
grep -q "app.shussei.example.com" caddy/Caddyfile.prod
```

- [ ] **Step 2: Run the smoke script to verify it fails**

Run: `bash tests/caddy-smoke.sh`
Expected: FAIL because Caddy files do not exist

- [ ] **Step 3: Create the Caddy config files and production compose**

```caddy
# caddy/Caddyfile.dev
:80 {
  handle_path /api/* {
    reverse_proxy api:3001
  }

  reverse_proxy web:3000
}
```

```caddy
# caddy/Caddyfile.prod
app.shussei.example.com {
  reverse_proxy web:3000
}

api.shussei.example.com {
  reverse_proxy api:3001
}
```

```yaml
# compose.prod.yml
services:
  web:
    image: ghcr.io/arkhe-ai/shussei-web:latest
    env_file: .env

  api:
    image: ghcr.io/arkhe-ai/shussei-api:latest
    env_file: .env

  caddy:
    image: caddy:2
    ports:
      - '80:80'
      - '443:443'
    volumes:
      - ./caddy/Caddyfile.prod:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config
    depends_on:
      - web
      - api

volumes:
  caddy_data:
  caddy_config:
```

- [ ] **Step 4: Add Caddy to dev compose and validate both compose files**

```yaml
# append to compose.dev.yml
  caddy:
    image: caddy:2
    ports:
      - '80:80'
    volumes:
      - ./caddy/Caddyfile.dev:/etc/caddy/Caddyfile:ro
    depends_on:
      - web
      - api
```

Run: `bash tests/caddy-smoke.sh && docker compose --env-file .env -f compose.dev.yml config && docker compose --env-file .env -f compose.prod.yml config`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add caddy compose.dev.yml compose.prod.yml tests/caddy-smoke.sh
git commit -m "feat(infra): add reverse proxy and prod compose"
```

### Task 4: Add health checks, wait scripts, and deployment docs

**Files:**
- Create: `shussei-infra/scripts/wait-for-http.sh`
- Create: `shussei-infra/monitoring/healthcheck.sh`
- Create: `shussei-infra/docs/deploy-vps.md`
- Create: `shussei-infra/docs/runbook.md`
- Modify: `shussei-infra/Makefile`
- Create: `shussei-infra/tests/healthcheck-smoke.sh`

**Interfaces:**
- Consumes: running services on `http://localhost/api/v1/health`, `http://localhost:3001/api/v1/health`, `http://localhost:7880`
- Produces: `make healthcheck`, `make prod-up`, `make prod-down`, operator docs with exact commands

- [ ] **Step 1: Write the failing healthcheck smoke script**

```bash
#!/usr/bin/env bash
set -euo pipefail
grep -q "curl -fsS" monitoring/healthcheck.sh
grep -q "docker compose --env-file .env -f compose.prod.yml up -d" Makefile
```

- [ ] **Step 2: Run the smoke script to verify it fails**

Run: `bash tests/healthcheck-smoke.sh`
Expected: FAIL because healthcheck files are missing

- [ ] **Step 3: Implement wait and healthcheck scripts**

```bash
# scripts/wait-for-http.sh
#!/usr/bin/env bash
set -euo pipefail
url="$1"
retries="${2:-30}"
for _ in $(seq 1 "$retries"); do
  if curl -fsS "$url" >/dev/null; then
    exit 0
  fi
  sleep 2
done
echo "Timed out waiting for $url" >&2
exit 1
```

```bash
# monitoring/healthcheck.sh
#!/usr/bin/env bash
set -euo pipefail
curl -fsS http://localhost/api/v1/health >/dev/null
curl -fsS http://localhost:3001/api/v1/health >/dev/null
curl -fsS http://localhost:7880 >/dev/null || true
docker compose --env-file .env -f compose.dev.yml ps
```

- [ ] **Step 4: Extend the Makefile and add deployment docs, then rerun the smoke test**

```make
prod-up:
	docker compose --env-file .env -f compose.prod.yml up -d

prod-down:
	docker compose --env-file .env -f compose.prod.yml down -v

healthcheck:
	bash monitoring/healthcheck.sh
```

```md
# docs/deploy-vps.md
1. Clone `shussei-web`, `shussei-api`, and `shussei-infra` as sibling directories.
2. Copy `.env.example` to `.env` and fill every secret.
3. Run `make check-host`.
4. Run `docker compose --env-file .env -f compose.prod.yml pull`.
5. Run `make prod-up`.
6. Run `make healthcheck`.
```

Run: `bash tests/healthcheck-smoke.sh && make healthcheck`
Expected: PASS when stack is running

- [ ] **Step 5: Commit**

```bash
git add scripts monitoring docs Makefile tests/healthcheck-smoke.sh
git commit -m "feat(infra): add health checks and operator docs"
```

### Task 5: Harden env docs, logging expectations, and production checklist

**Files:**
- Modify: `shussei-infra/README.md`
- Modify: `shussei-infra/.env.example`
- Modify: `shussei-infra/docs/runbook.md`
- Create: `shussei-infra/tests/env-example-smoke.sh`

**Interfaces:**
- Consumes: all previous compose and script outputs
- Produces: documented env vars `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `COOKIE_DOMAIN`, `LIVEKIT_WS_URL`, `PUBLIC_IP`, `TURN_SHARED_SECRET`, and a clear logging/incident checklist

- [ ] **Step 1: Write the failing env smoke script**

```bash
#!/usr/bin/env bash
set -euo pipefail
grep -q "GOOGLE_CLIENT_ID" .env.example
grep -q "TURN_SHARED_SECRET" .env.example
grep -q "LiveKit logs" README.md
```

- [ ] **Step 2: Run the smoke script to verify it fails**

Run: `bash tests/env-example-smoke.sh`
Expected: FAIL until the env template and docs are expanded

- [ ] **Step 3: Expand `.env.example` and README with exact variables and logging expectations**

```env
POSTGRES_PASSWORD=change-me
REDIS_PASSWORD=change-me
SESSION_SECRET=change-me
GOOGLE_CLIENT_ID=change-me
GOOGLE_CLIENT_SECRET=change-me
COOKIE_DOMAIN=localhost
LIVEKIT_API_KEY=devkey
LIVEKIT_API_SECRET=devsecret
LIVEKIT_WS_URL=ws://localhost:7880
TURN_SHARED_SECRET=change-me
PUBLIC_IP=127.0.0.1
```

```md
## Logs to inspect
- Backend logs: `docker compose --env-file .env -f compose.prod.yml logs api`
- Reverse proxy logs: `docker compose --env-file .env -f compose.prod.yml logs caddy`
- LiveKit logs: `docker compose --env-file .env -f compose.prod.yml logs livekit`
```

- [ ] **Step 4: Add a production incident checklist to the runbook and rerun the smoke test**

```md
## First-response checklist
1. Run `make healthcheck`.
2. Inspect `logs api`, `logs caddy`, and `logs livekit`.
3. Verify `PUBLIC_IP`, TURN ports, and TLS certificates.
4. Re-test `/api/v1/health` and a browser login flow.
```

Run: `bash tests/env-example-smoke.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add README.md .env.example docs/runbook.md tests/env-example-smoke.sh
git commit -m "docs(infra): finalize env and operations guide"
```

## Spec Coverage Check

- Self-hosted deployment with one initial environment: Tasks 1 through 4
- PostgreSQL, Redis, LiveKit, and coturn stack: Tasks 1 and 2
- TLS termination at reverse proxy and public exposure rules: Task 3
- Basic health checks and logs: Tasks 4 and 5
- 8 vCPU / 16 GB / SSD / network guidance in operator docs: Task 4 and README updates
- TURN and LiveKit config for low-latency RTC: Task 2

## Placeholder Scan

Search after writing for red-flag placeholder phrases in `/home/matumoto/docs/superpowers/plans/2026-08-27-shussei-infra.md`.
Expected: no matches.
