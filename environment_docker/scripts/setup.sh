#!/bin/bash
# WebArena Docker Setup Script
# Usage: ./environment_docker/scripts/setup.sh [--full]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
cd "$PROJECT_DIR"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${GREEN}WebArena Docker Setup${NC}"
echo ""

# Determine compose file
if [ "$1" == "--full" ]; then
    COMPOSE_FILE="docker-compose.yml"
    echo "Mode: Full setup (with WebArena websites)"
else
    COMPOSE_FILE="docker-compose.test.yml"
    echo "Mode: Test setup (mock server)"
fi
echo ""

# Step 1: Check Prerequisites
echo -e "${GREEN}Step 1: Check Prerequisites${NC}"

echo -n "  Checking Docker... "
if ! command -v docker &> /dev/null; then
    echo -e "${RED}not found${NC}"
    echo "  Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi
echo -e "${GREEN}$(docker --version | cut -d' ' -f3 | tr -d ',')${NC}"

echo -n "  Checking Docker Compose... "
if ! docker compose version &> /dev/null; then
    echo -e "${RED}not found${NC}"
    exit 1
fi
echo -e "${GREEN}$(docker compose version --short)${NC}"

echo -n "  Checking Docker daemon... "
if ! docker info &> /dev/null; then
    echo -e "${RED}not running${NC}"
    exit 1
fi
echo -e "${GREEN}running${NC}"
echo ""

# Step 2: Create Directory Structure
echo -e "${GREEN}Step 2: Create Directory Structure${NC}"
mkdir -p .auth log_files cache/results config_files data/wikipedia .docker-images
echo "  Created: .auth/ log_files/ cache/results/ config_files/"
echo ""

# Step 3: Configure Environment
echo -e "${GREEN}Step 3: Configure Environment Variables${NC}"
if [ ! -f .env ]; then
    cp .env.example .env
    echo "  Created .env from template"
    echo -e "  ${YELLOW}Edit .env with your Azure credentials${NC}"
else
    echo "  .env already exists"
fi
echo ""

# Step 4: Build Docker Image
echo -e "${GREEN}Step 4: Build Docker Image${NC}"
echo "  Building with:"
echo "    - Python 3.10"
echo "    - uv package manager"
echo "    - uv virtual environment (.venv)"
echo "    - Playwright browser"
echo ""
docker compose -f "$COMPOSE_FILE" build webarena
echo ""

# Step 5: Verify Installation
echo -e "${GREEN}Step 5: Verify Installation${NC}"

docker compose -f "$COMPOSE_FILE" up -d 2>/dev/null

echo -n "  Python version... "
PYTHON_VER=$(docker compose -f "$COMPOSE_FILE" run --rm webarena python --version 2>&1 | tr -d '\n')
echo -e "${GREEN}$PYTHON_VER${NC}"

echo -n "  uv version... "
UV_VER=$(docker compose -f "$COMPOSE_FILE" run --rm webarena uv --version 2>&1 | tr -d '\n')
echo -e "${GREEN}$UV_VER${NC}"

echo -n "  Virtual environment... "
VENV_PATH=$(docker compose -f "$COMPOSE_FILE" run --rm webarena python -c "import sys; print(sys.prefix)" 2>&1 | tr -d '\n')
echo -e "${GREEN}$VENV_PATH${NC}"

echo -n "  Playwright... "
docker compose -f "$COMPOSE_FILE" run --rm webarena python -c "from playwright.sync_api import sync_playwright; print('OK')" 2>/dev/null
echo ""

# Step 6: Verify WebArena Modules
echo -e "${GREEN}Step 6: Verify WebArena Modules${NC}"

echo -n "  browser_env... "
docker compose -f "$COMPOSE_FILE" run --rm webarena python -c "from browser_env import ScriptBrowserEnv; print('OK')" 2>/dev/null

echo -n "  evaluation_harness... "
docker compose -f "$COMPOSE_FILE" run --rm webarena python -c "from evaluation_harness import evaluator_router; print('OK')" 2>/dev/null

echo -n "  agent... "
docker compose -f "$COMPOSE_FILE" run --rm webarena python -c "from agent import construct_agent; print('OK')" 2>/dev/null
echo ""

# Step 7: Cleanup
echo -e "${GREEN}Step 7: Cleanup${NC}"
docker compose -f "$COMPOSE_FILE" down 2>/dev/null
echo "  Stopped test containers"
echo ""

# Done
echo -e "${GREEN}Setup Complete!${NC}"
echo ""
echo "Next steps:"
if ! grep -q "AZURE_OPENAI_API_KEY=." .env 2>/dev/null; then
    echo "  1. ./environment_docker/scripts/configure_azure.sh"
    echo "  2. ./environment_docker/scripts/run_benchmark.sh"
else
    echo "  ./environment_docker/scripts/run_benchmark.sh"
fi
echo ""
