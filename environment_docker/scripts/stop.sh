#!/bin/bash
# Stop WebArena Docker Services
# Usage: ./environment_docker/scripts/stop.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

cd "$PROJECT_DIR"

echo "Stopping WebArena services..."

# Stop both compose files
docker compose -f docker-compose.test.yml down 2>/dev/null
docker compose -f docker-compose.yml down 2>/dev/null

echo "All services stopped."
