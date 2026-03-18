#!/bin/bash
# Azure AI Foundry Configuration Script
# Usage: ./environment_docker/scripts/configure_azure.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
cd "$PROJECT_DIR"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${GREEN}Azure AI Foundry Configuration${NC}"
echo ""
echo "You need these from Azure Portal:"
echo "  - API Key (Keys and Endpoint > KEY 1)"
echo "  - Endpoint URL (Keys and Endpoint > Endpoint)"
echo "  - Deployment name (Model deployments)"
echo ""

# Prompt for values
read -p "Azure OpenAI API Key: " -s NEW_API_KEY
echo ""
read -p "Endpoint (https://xxx.openai.azure.com/): " NEW_ENDPOINT
read -p "Deployment Name (e.g., gpt-4o): " NEW_DEPLOYMENT
read -p "API Version [2024-02-15-preview]: " NEW_API_VERSION
NEW_API_VERSION="${NEW_API_VERSION:-2024-02-15-preview}"

# Validate
if [ -z "$NEW_API_KEY" ] || [ -z "$NEW_ENDPOINT" ] || [ -z "$NEW_DEPLOYMENT" ]; then
    echo -e "${YELLOW}Error: All fields required.${NC}"
    exit 1
fi

# Remove trailing slash
NEW_ENDPOINT="${NEW_ENDPOINT%/}"

# Write .env
cat > .env << EOF
# WebArena Configuration - $(date)

# Azure OpenAI
OPENAI_API_TYPE=azure
AZURE_OPENAI_API_KEY=$NEW_API_KEY
AZURE_OPENAI_ENDPOINT=$NEW_ENDPOINT
AZURE_OPENAI_API_VERSION=$NEW_API_VERSION
AZURE_OPENAI_DEPLOYMENT=$NEW_DEPLOYMENT

# WebArena URLs
SHOPPING=http://shopping:80
SHOPPING_ADMIN=http://shopping_admin:80/admin
REDDIT=http://forum:80
GITLAB=http://gitlab:8023
MAP=http://map:3000
WIKIPEDIA=http://wikipedia:80/wikipedia_en_all_maxi_2022-05/A/User:The_other_Kiwix_guy/Landing
HOMEPAGE=PASS
EOF

echo ""
echo "Saved to .env"
echo ""

# Test
echo "Testing connection..."
docker compose -f docker-compose.test.yml run --rm webarena python -c "
from llms.providers.openai_utils import setup_openai_api
import openai
setup_openai_api()
print(f'  Endpoint: {openai.api_base}')
print('  Status: OK')
" 2>/dev/null

echo ""
echo -e "${GREEN}Configuration complete!${NC}"
echo "Run: ./environment_docker/scripts/run_benchmark.sh"
