#!/bin/bash
# Mothership Core Core Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/chriscarterux/Mothership---Core/main/install.sh | bash

set -e

echo ""
echo "Mothership Core Installer"
echo ""

# Detect if we're in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a git repository. Initialize with 'git init' first."
    exit 1
fi

# Ask for install type
echo "Install type:"
echo "  1) minimal - Just the core prompt (recommended)"
echo "  2) full    - Core prompt + specialized agents"
echo ""
read -p "Choice [1/2]: " INSTALL_CHOICE

case "$INSTALL_CHOICE" in
    2|full) INSTALL_TYPE="full" ;;
    *) INSTALL_TYPE="minimal" ;;
esac

# Create .mothership directory
mkdir -p .mothership

# Download files
BASE_URL="https://raw.githubusercontent.com/chriscarterux/Mothership---Core/main"

echo "Downloading Mothership Core..."
curl -fsSL "$BASE_URL/mothership.md" -o .mothership/mothership.md

if [ "$INSTALL_TYPE" == "full" ]; then
    echo "Downloading specialized agents..."
    mkdir -p .mothership/agents
    curl -fsSL "$BASE_URL/agents/cipher.md" -o .mothership/agents/cipher.md
    curl -fsSL "$BASE_URL/agents/vector.md" -o .mothership/agents/vector.md
    curl -fsSL "$BASE_URL/agents/cortex.md" -o .mothership/agents/cortex.md
    curl -fsSL "$BASE_URL/agents/sentinel.md" -o .mothership/agents/sentinel.md
fi

# Download loop script
curl -fsSL "$BASE_URL/mothership.sh" -o mothership.sh
chmod +x mothership.sh

# Create initial checkpoint
cat > .mothership/checkpoint.md << 'EOF'
phase: ready
project: null
branch: null
story: null
EOF

# Add to .gitignore
if [ -f .gitignore ]; then
    if ! grep -q "progress.md" .gitignore; then
        echo "" >> .gitignore
        echo "# Mothership Core" >> .gitignore
        echo "progress.md" >> .gitignore
    fi
else
    echo "# Mothership Core" > .gitignore
    echo "progress.md" >> .gitignore
fi

echo ""
echo "Installation complete!"
echo ""
echo "Created:"
echo "  .mothership/         - Configuration"
echo "  mothership.sh        - Loop script"
echo ""
echo "Next steps:"
echo "  1. Run: ./mothership.sh doctor"
echo "  2. Run: ./mothership.sh benchmark"
echo "  3. Add docs to ./docs/ describing your feature"
echo "  4. Run: ./mothership.sh plan \"your feature\""
echo ""
