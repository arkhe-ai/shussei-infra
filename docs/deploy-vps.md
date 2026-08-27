# Deployment to VPS

## Prerequisites

- VPS with 8 vCPU, 16 GB RAM, SSD storage
- Docker and docker-compose installed
- Public static IP

## Deployment Steps

1. Clone the three repos as siblings:
   ```bash
   git clone https://github.com/arkhe-ai/shussei-web.git
   git clone https://github.com/arkhe-ai/shussei-api.git
   git clone https://github.com/arkhe-ai/shussei-infra.git
   ```

2. Copy and configure `.env`:
   ```bash
   cd shussei-infra
   cp .env.example .env
   # Edit .env with your secrets and domain
   ```

3. Check host:
   ```bash
   make check-host
   ```

4. Pull images:
   ```bash
   docker compose --env-file .env -f compose.prod.yml pull
   ```

5. Start the stack:
   ```bash
   make prod-up
   ```

6. Verify health:
   ```bash
   make healthcheck
   ```

## DNS Configuration

Update your DNS records to point to the VPS public IP:
- `app.shussei.example.com` → VPS IP
- `api.shussei.example.com` → VPS IP

Caddy will obtain TLS certificates automatically via Let's Encrypt.
