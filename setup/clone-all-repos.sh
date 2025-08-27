#!/bin/bash
# Clone all Jedsy repositories
# This script clones all Jedsy repositories into the correct locations

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Cloning all Jedsy repositories...${NC}"

# Define paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DEV_INFRA_DIR="$(dirname "$SCRIPT_DIR")"
JEDSY_DIR="$(dirname "$DEV_INFRA_DIR")"

# Define repositories to clone
REPOS=(
    "git@github.com:PackageGlider/nebula-healthcheck-service.git"
    "git@github.com:PackageGlider/vpn-dashboard.git"
    "git@github.com:PackageGlider/nebula-vpn-pki.git"
    "git@github.com:PackageGlider/monitor-service.git"
    "git@github.com:PackageGlider/iac.git"
)

# Clone or update repositories
for REPO in "${REPOS[@]}"; do
    # Extract repo name from URL
    REPO_NAME=$(basename "$REPO" .git)
    REPO_PATH="$JEDSY_DIR/$REPO_NAME"
    
    if [ -d "$REPO_PATH" ]; then
        echo -e "${GREEN}Repository $REPO_NAME already exists, updating...${NC}"
        cd "$REPO_PATH" && git pull
    else
        echo -e "${GREEN}Cloning $REPO_NAME...${NC}"
        git clone "$REPO" "$REPO_PATH"
    fi
done

echo -e "${GREEN}All repositories cloned or updated!${NC}"
echo -e "${BLUE}Next, run setup-workspace.sh to configure the workspace.${NC}"
