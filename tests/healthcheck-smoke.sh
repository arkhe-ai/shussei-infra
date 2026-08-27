#!/usr/bin/env bash
set -euo pipefail
grep -q "curl -fsS" monitoring/healthcheck.sh
grep -q "docker compose --env-file .env -f compose.prod.yml up -d" Makefile
