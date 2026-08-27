# Shussei Operations Runbook

## Monitoring

Check stack health:
```bash
make healthcheck
```

## Logs

View backend logs:
```bash
docker compose --env-file .env -f compose.dev.yml logs api
```

View reverse proxy logs:
```bash
docker compose --env-file .env -f compose.dev.yml logs caddy
```

View LiveKit logs:
```bash
docker compose --env-file .env -f compose.dev.yml logs livekit
```

## First-Response Checklist

1. Run health checks:
   ```bash
   make healthcheck
   ```

2. Inspect logs:
   ```bash
   docker compose --env-file .env -f compose.dev.yml logs api | tail -50
   docker compose --env-file .env -f compose.dev.yml logs caddy | tail -50
   docker compose --env-file .env -f compose.dev.yml logs livekit | tail -50
   ```

3. Verify `PUBLIC_IP`, TURN ports, and TLS certificates

4. Test authentication:
   ```bash
   curl -sS http://localhost/api/v1/health | jq .
   ```

5. Test browser login at `http://localhost/login`

## Common Issues

### Services not starting
- Check `.env` variables are set correctly
- Verify ports 80, 443, 3000, 3001, 7880, 3478 are available
- Check Docker has enough disk space

### WebSocket connection failing
- Verify Caddy is running: `docker compose ps caddy`
- Check firewall allows WebSocket upgrades on port 80/443

### Screen sharing not working
- Only Chrome/Edge desktop officially supported in MVP
- Check browser permissions for screen capture
- Verify TURN/STUN connectivity on ports 3478/5349
