#!/usr/bin/env bash
set -euo pipefail
grep -q "keys:" livekit/livekit.yaml
grep -q "use-auth-secret" turn/turnserver.conf
