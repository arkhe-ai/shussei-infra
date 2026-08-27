SHELL := /bin/bash

check-host:
	bash scripts/check-host.sh

dev-up:
	docker compose --env-file .env -f compose.dev.yml up -d --build

dev-down:
	docker compose --env-file .env -f compose.dev.yml down -v
