#!/usr/bin/env bash
set -euo pipefail
command -v docker >/dev/null || { echo 'docker is required'; exit 1; }
docker compose version >/dev/null || { echo 'docker compose is required'; exit 1; }
echo 'docker and docker compose are available'
