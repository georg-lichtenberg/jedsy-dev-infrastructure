#!/bin/bash
# Setup Jedsy development workspace
# This script sets up the Jedsy development workspace

# Define colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Setting up Jedsy development workspace...${NC}"

# Define paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DEV_INFRA_DIR="$(dirname "$SCRIPT_DIR")"
JEDSY_DIR="$(dirname "$DEV_INFRA_DIR")"
WORKSPACE_FILE="$DEV_INFRA_DIR/workspaces/jedsy-all.code-workspace"

# Check if Jedsy directory exists
if [ ! -d "$JEDSY_DIR" ]; then
    echo -e "${RED}Error: Jedsy directory not found at $JEDSY_DIR${NC}"
    exit 1
fi

# Check if workspace file exists
if [ ! -f "$WORKSPACE_FILE" ]; then
    echo -e "${RED}Error: Workspace file not found at $WORKSPACE_FILE${NC}"
    exit 1
fi

# Create symlink to workspace file in Jedsy directory
echo -e "${GREEN}Creating symlink to workspace file...${NC}"
ln -sf "$WORKSPACE_FILE" "$JEDSY_DIR/jedsy.code-workspace"

echo -e "${GREEN}Workspace setup complete!${NC}"
echo -e "${BLUE}You can now open VS Code with:${NC}"
echo -e "${GREEN}code $JEDSY_DIR/jedsy.code-workspace${NC}"
