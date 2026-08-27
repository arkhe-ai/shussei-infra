#!/usr/bin/env bash
set -euo pipefail
grep -q "reverse_proxy web:3000" caddy/Caddyfile.dev
grep -q "app.shussei.example.com" caddy/Caddyfile.prod
