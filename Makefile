SHELL := /bin/bash

check-host:
	bash scripts/check-host.sh

dev-up:
	docker compose --env-file .env -f compose.dev.yml up -d --build

dev-down:
	docker compose --env-file .env -f compose.dev.yml down -v

prod-up:
	docker compose --env-file .env -f compose.prod.yml up -d

prod-down:
	docker compose --env-file .env -f compose.prod.yml down -v

healthcheck:
	bash monitoring/healthcheck.sh
