# Shussei Infrastructure

Self-hosted deployment stack for Shussei MVP using Docker Compose.

## Quick Start

```bash
make check-host
cp .env.example .env
# Edit .env with your secrets
make dev-up
make healthcheck
```

## Development

The development stack builds from sibling repos:
- `../shussei-web`
- `../shussei-api`

Services:
- web: Next.js app (port 3000)
- api: NestJS backend (port 3001)
- postgres: PostgreSQL database
- redis: Redis cache
- livekit: LiveKit SFU media server
- coturn: TURN/STUN NAT traversal
- caddy: Reverse proxy

## Production

Use `compose.prod.yml` with registry images:
```bash
docker compose -f compose.prod.yml pull
docker compose -f compose.prod.yml up -d
```

## Documentation

- `docs/deploy-vps.md` — deployment checklist
- `docs/runbook.md` — operations guide
