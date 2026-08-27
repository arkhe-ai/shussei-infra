#!/usr/bin/env bash
set -euo pipefail
output=$(bash scripts/check-host.sh 2>&1 || true)
echo "$output" | grep -q "docker"
