#!/bin/bash

# NenaBot Documentation Generator
# Generates Doxygen documentation for both Python (backend) and TypeScript (frontend) code
# Usage: ./scripts/generate-docs.sh [--open]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}NenaBot Documentation Generator${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# Check if Doxygen is installed
if ! command -v doxygen &> /dev/null; then
    echo -e "${RED}Error: doxygen not found${NC}"
    echo "Please install doxygen:"
    echo "  Ubuntu/Debian: sudo apt-get install doxygen"
    echo "  macOS:         brew install doxygen"
    echo "  Windows:       choco install doxygen (or download from doxygen.nl)"
    exit 1
fi

echo -e "${GREEN}✓ Doxygen found: $(doxygen --version)${NC}"
echo

# Change to project root
cd "$PROJECT_ROOT"

# Run Doxygen
echo -e "${YELLOW}Generating documentation...${NC}"
if doxygen Doxyfile; then
    echo -e "${GREEN}✓ Documentation generated successfully${NC}"
    echo
    
    # Check for TypeScript filter warnings
    if [ -f "docs/generated/html/index.html" ]; then
        echo -e "${GREEN}✓ Output files created in docs/generated/${NC}"
        
        # Optionally open in browser
        if [ "$1" = "--open" ]; then
            echo -e "${YELLOW}Opening documentation in browser...${NC}"
            if command -v xdg-open &> /dev/null; then
                # Linux
                xdg-open "docs/generated/html/index.html" &
            elif command -v open &> /dev/null; then
                # macOS
                open "docs/generated/html/index.html"
            elif command -v start &> /dev/null; then
                # Windows (Git Bash, MSYS2, etc.)
                start "docs/generated/html/index.html"
            fi
        else
            echo -e "${BLUE}To view documentation, open: file://$PROJECT_ROOT/docs/generated/html/index.html${NC}"
        fi
    fi
else
    echo -e "${RED}✗ Doxygen generation failed${NC}"
    exit 1
fi

echo
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Documentation generation complete!${NC}"
echo -e "${BLUE}========================================${NC}"
