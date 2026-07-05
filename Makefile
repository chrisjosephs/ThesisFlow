.DEFAULT_GOAL := help

# Pull in .env so variables like POSTGRES_DB are available
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

POSTGRES_CONTAINER := thesisflow_postgres
POSTGRES_DB        ?= thesisflow

# Detect OS for backup script
ifeq ($(OS),Windows_NT)
    BACKUP_CMD := powershell -NonInteractive -File ./database/backup.ps1
    DEV_CMD    := powershell -NonInteractive -File ./dev.ps1
else
    BACKUP_CMD := ./database/backup.sh
    DEV_CMD    := ./dev.sh
endif

.PHONY: help \
        dev \
        up down restart ps logs \
        tools \
        db-shell db-shell-app db-shell-ro db-logs db-backup db-reset \
        engine-install engine-dev \
        web-install web-dev

# -----------------------------------------------------------------------------

help:
	@echo ""
	@echo "ThesisFlow"
	@echo ""
	@echo "  Dev"
	@echo "    make dev              Start everything (Docker + engine) with health check"
	@echo ""
	@echo "  Infrastructure"
	@echo "    make up               Start postgres + redis"
	@echo "    make down             Stop all services"
	@echo "    make restart          Restart all services"
	@echo "    make ps               Show running containers"
	@echo "    make logs             Tail all container logs"
	@echo "    make tools            Also start pgAdmin  (http://localhost:5050)"
	@echo ""
	@echo "  Database"
	@echo "    make db-shell         psql as superuser"
	@echo "    make db-shell-app     psql as thesisflow_app (runtime user)"
	@echo "    make db-shell-ro      psql as thesisflow_readonly"
	@echo "    make db-logs          Tail postgres logs only"
	@echo "    make db-backup        Run backup script"
	@echo "    make db-seed          Insert example theses from example-theses/*.json"
	@echo "    make db-reset         !! Drop all data and reinitialise from scratch"
	@echo ""
	@echo "  Engine (NestJS)"
	@echo "    make engine-install   Install engine dependencies"
	@echo "    make engine-dev       Start engine in watch mode"
	@echo ""
	@echo "  Web (Next.js)"
	@echo "    make web-install      Install web dependencies"
	@echo "    make web-dev          Start web dev server"
	@echo ""

# -----------------------------------------------------------------------------
# Dev
# -----------------------------------------------------------------------------

dev:
	$(DEV_CMD)

# -----------------------------------------------------------------------------
# Infrastructure
# -----------------------------------------------------------------------------

up:
	docker compose up -d

down:
	docker compose down

restart:
	docker compose restart

ps:
	docker compose ps

logs:
	docker compose logs -f

tools:
	docker compose --profile tools up -d

# -----------------------------------------------------------------------------
# Database
# -----------------------------------------------------------------------------

db-shell:
	docker exec -it $(POSTGRES_CONTAINER) psql -U postgres -d $(POSTGRES_DB)

db-shell-app:
	docker exec -it $(POSTGRES_CONTAINER) psql -U thesisflow_app -d $(POSTGRES_DB)

db-shell-ro:
	docker exec -it $(POSTGRES_CONTAINER) psql -U thesisflow_readonly -d $(POSTGRES_DB)

db-logs:
	docker compose logs -f postgres

db-backup:
	$(BACKUP_CMD)

db-seed:
	pnpm install --silent
	node database/seed.js

db-reset:
	@echo ""
	@echo "!! WARNING: This will permanently delete all data."
	@echo "   Press Ctrl+C to cancel."
	@echo ""
	@read -p "Press Enter to continue..." confirm
	docker compose down -v
	docker compose up -d

# -----------------------------------------------------------------------------
# Engine (NestJS)
# -----------------------------------------------------------------------------

engine-install:
	cd thesisflow-engine && pnpm install

engine-dev:
	cd thesisflow-engine && pnpm run start:dev

# -----------------------------------------------------------------------------
# Web (Next.js)
# -----------------------------------------------------------------------------

web-install:
	cd thesisflow-web && pnpm install

web-dev:
	cd thesisflow-web && pnpm run dev
