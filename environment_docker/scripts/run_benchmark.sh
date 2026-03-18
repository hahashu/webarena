#!/bin/bash
# WebArena Benchmark Runner
# Usage: ./environment_docker/scripts/run_benchmark.sh [start_idx] [end_idx] [model]
#
# Examples:
#   ./environment_docker/scripts/run_benchmark.sh              # Run test 0-1
#   ./environment_docker/scripts/run_benchmark.sh 0 10         # Run tests 0-9
#   ./environment_docker/scripts/run_benchmark.sh 0 100 gpt-4  # Run tests 0-99 with gpt-4

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
cd "$PROJECT_DIR"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default values
START_IDX="${1:-0}"
END_IDX="${2:-1}"
MODEL="${3:-gpt-4o}"
RESULT_DIR="results/run_$(date +%Y%m%d_%H%M%S)"

# Determine compose file
if docker images | grep -q "postmill-populated"; then
    COMPOSE_FILE="docker-compose.yml"
else
    COMPOSE_FILE="docker-compose.test.yml"
fi

echo ""
echo -e "${GREEN}WebArena Benchmark Runner${NC}"
echo ""
echo "  Test range: $START_IDX - $END_IDX"
echo "  Model: $MODEL"
echo "  Results: $RESULT_DIR"
echo ""

# Check .env
if [ ! -f .env ]; then
    echo -e "${YELLOW}Error: .env not found. Run ./environment_docker/scripts/setup.sh first.${NC}"
    exit 1
fi

if ! grep -q "AZURE_OPENAI_API_KEY=." .env && ! grep -q "OPENAI_API_KEY=sk-" .env; then
    echo -e "${YELLOW}Warning: No API key in .env. Run ./environment_docker/scripts/configure_azure.sh${NC}"
    exit 1
fi

# Start services
echo "Starting services..."
docker compose -f "$COMPOSE_FILE" up -d
sleep 2

# Generate configs if needed
if [ ! -f "config_files/0.json" ]; then
    echo "Generating test configurations..."
    docker compose -f "$COMPOSE_FILE" run --rm webarena \
        python scripts/generate_test_data.py
fi

# Run benchmark
echo ""
echo "Running benchmark..."
echo ""

docker compose -f "$COMPOSE_FILE" run --rm webarena \
    python run.py \
    --instruction_path agent/prompts/jsons/p_cot_id_actree_2s.json \
    --test_start_idx "$START_IDX" \
    --test_end_idx "$END_IDX" \
    --model "$MODEL" \
    --result_dir "$RESULT_DIR"

echo ""
echo -e "${GREEN}Benchmark Complete!${NC}"
echo "Results: $RESULT_DIR"
echo ""
echo "Stop services: docker compose -f $COMPOSE_FILE down"
