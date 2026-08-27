#!/usr/bin/env bash
set -euo pipefail
grep -q "GOOGLE_CLIENT_ID" .env.example
grep -q "TURN_SHARED_SECRET" .env.example
grep -q "LiveKit logs" README.md
