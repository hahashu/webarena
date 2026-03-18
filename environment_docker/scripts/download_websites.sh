#!/bin/bash
# Download WebArena Website Docker Images
# Usage: ./environment_docker/scripts/download_websites.sh [component]
#
# Components: forum, shopping, gitlab, wikipedia, all

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
cd "$PROJECT_DIR"

mkdir -p .docker-images data/wikipedia

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# URLs
FORUM_URL="http://metis.lti.cs.cmu.edu/webarena-images/postmill-populated-exposed-withimg.tar"
SHOPPING_URL="http://metis.lti.cs.cmu.edu/webarena-images/shopping_final_0712.tar"
SHOPPING_ADMIN_URL="http://metis.lti.cs.cmu.edu/webarena-images/shopping_admin_final_0719.tar"
GITLAB_URL="http://metis.lti.cs.cmu.edu/webarena-images/gitlab-populated-final-port8023.tar"
WIKIPEDIA_URL="http://metis.lti.cs.cmu.edu/webarena-images/wikipedia_en_all_maxi_2022-05.zim"

download_and_load() {
    local name=$1
    local url=$2
    local image_name=$3
    local filename=$(basename "$url")

    echo ""
    echo -e "${GREEN}$name${NC}"

    if docker images | grep -q "$image_name"; then
        echo "  Already loaded, skipping."
        return 0
    fi

    if [ ! -f ".docker-images/$filename" ]; then
        echo "  Downloading..."
        curl -L --progress-bar -o ".docker-images/$filename" "$url"
    else
        echo "  Using cached file"
    fi

    echo "  Loading into Docker..."
    docker load --input ".docker-images/$filename"
    echo "  Done"
}

case "${1:-help}" in
    forum)
        download_and_load "Forum (~50GB)" "$FORUM_URL" "postmill-populated"
        ;;
    shopping)
        download_and_load "Shopping" "$SHOPPING_URL" "shopping_final"
        download_and_load "Shopping Admin" "$SHOPPING_ADMIN_URL" "shopping_admin"
        ;;
    gitlab)
        download_and_load "GitLab" "$GITLAB_URL" "gitlab-populated"
        ;;
    wikipedia)
        echo ""
        echo -e "${GREEN}Wikipedia (~90GB)${NC}"
        if [ -f "data/wikipedia/wikipedia_en_all_maxi_2022-05.zim" ]; then
            echo "  Already exists, skipping."
        else
            echo "  Downloading..."
            curl -L --progress-bar -o "data/wikipedia/wikipedia_en_all_maxi_2022-05.zim" "$WIKIPEDIA_URL"
        fi
        ;;
    all)
        download_and_load "Forum" "$FORUM_URL" "postmill-populated"
        download_and_load "Shopping" "$SHOPPING_URL" "shopping_final"
        download_and_load "Shopping Admin" "$SHOPPING_ADMIN_URL" "shopping_admin"
        download_and_load "GitLab" "$GITLAB_URL" "gitlab-populated"
        echo ""
        read -p "Download Wikipedia (~90GB)? [y/N]: " wiki
        if [ "$wiki" = "y" ]; then
            curl -L --progress-bar -o "data/wikipedia/wikipedia_en_all_maxi_2022-05.zim" "$WIKIPEDIA_URL"
        fi
        ;;
    *)
        echo ""
        echo -e "${GREEN}WebArena Website Downloader${NC}"
        echo ""
        echo "Usage: $0 [component]"
        echo ""
        echo "Components:"
        echo "  forum      Forum (~50GB)"
        echo "  shopping   Shopping + Admin (~50GB)"
        echo "  gitlab     GitLab (~25GB)"
        echo "  wikipedia  Wikipedia (~90GB)"
        echo "  all        Everything"
        echo ""
        exit 0
        ;;
esac

echo ""
echo -e "${GREEN}Download Complete${NC}"
echo ""
docker images | grep -E "(shopping|postmill|gitlab)" || echo "  (no images loaded)"
