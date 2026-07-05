#!/usr/bin/env bash
# Start the full ThesisFlow dev environment.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENGINE="$ROOT/thesisflow-engine"

CYAN='\033[0;36m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
GRAY='\033[0;90m'
RED='\033[0;31m'
NC='\033[0m'

step() { echo -e "  ${YELLOW}->  $1${NC}"; }
ok()   { echo -e "  ${GREEN}    $1${NC}"; }
fail() { echo -e "  ${RED}    ERROR: $1${NC}"; exit 1; }

echo ""
echo -e "  ${CYAN}ThesisFlow${NC}"
echo -e "  ${GRAY}─────────────────────────────────────────${NC}"
echo ""

# ── 1. Check Docker daemon ────────────────────────────────────────────────────

if ! docker info &>/dev/null; then
    fail "Docker daemon is not running. Start Docker and try again."
fi
ok "Docker running."
echo ""

# ── 2. Start Docker services ──────────────────────────────────────────────────

step "Starting Docker services..."
docker compose -f "$ROOT/docker-compose.yml" up -d
ok "Services started."
echo ""

# ── 3. Wait for PostgreSQL ────────────────────────────────────────────────────

step "Waiting for PostgreSQL..."
for i in $(seq 1 30); do
    if docker compose exec -T postgres pg_isready -U postgres &>/dev/null; then break; fi
    if [ "$i" -eq 30 ]; then fail "PostgreSQL did not become ready after 30s."; fi
    sleep 1
done
ok "PostgreSQL ready."
echo ""

# ── 4. Start engine in background, poll health ────────────────────────────────

step "Starting engine..."
cd "$ENGINE"
pnpm start:dev &
ENGINE_PID=$!
cd "$ROOT"

step "Waiting for engine to be healthy..."
for i in $(seq 1 60); do
    if curl -sf http://localhost:3001/api/health &>/dev/null; then break; fi
    if [ "$i" -eq 60 ]; then
        kill "$ENGINE_PID" 2>/dev/null || true
        fail "Engine did not respond after 60s. Check logs above."
    fi
    sleep 1
done

# ── 5. Status panel ───────────────────────────────────────────────────────────

echo ""
echo -e "  ${GRAY}─────────────────────────────────────────${NC}"
echo -e "  ${GREEN}ThesisFlow is ready${NC}"
echo -e "  ${GRAY}─────────────────────────────────────────${NC}"
echo ""
echo -e "  Engine API   http://localhost:3001/api"
echo -e "  Health       http://localhost:3001/api/health"
echo ""
echo -e "  ${GRAY}pgAdmin      http://localhost:5050"
echo -e "               (start with: docker compose --profile tools up -d)"
echo ""
echo -e "  Press Ctrl+C to stop the engine.${NC}"
echo ""

# ── 6. Bring engine logs to foreground ────────────────────────────────────────

wait "$ENGINE_PID"
