#!/usr/bin/env bash
set -euo pipefail
curl -fsS http://localhost/api/v1/health >/dev/null
curl -fsS http://localhost:3001/api/v1/health >/dev/null
curl -fsS http://localhost:7880 >/dev/null || true
docker compose --env-file .env -f compose.dev.yml ps
