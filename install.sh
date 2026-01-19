#!/bin/bash
# Mothership Core Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/chriscarterux/Mothership---Core/main/install.sh | bash

set -e

# Checksum verification for supply-chain integrity
# NOTE: Same-origin checksums protect against transit corruption and partial
# cache poisoning, but NOT against full server compromise. For stronger
# guarantees, pin checksums.sha256 hash in this script or use GPG signatures.
verify_checksum() {
    local file="$1"
    local expected="$2"
    if [ -z "$expected" ]; then
        echo "Warning: No checksum found for $file, skipping verification"
        return 0
    fi
    if command -v sha256sum &> /dev/null; then
        local actual=$(sha256sum "$file" | cut -d' ' -f1)
    elif command -v shasum &> /dev/null; then
        local actual=$(shasum -a 256 "$file" | cut -d' ' -f1)
    else
        echo "Warning: No checksum tool available, skipping verification"
        return 0
    fi
    if [ "$actual" != "$expected" ]; then
        echo "Checksum mismatch for $file"
        echo "Expected: $expected"
        echo "Actual:   $actual"
        rm -f "$file"
        exit 1
    fi
}

# Version pinning - use env var or default to main
VERSION="${MOTHERSHIP_VERSION:-main}"

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
BASE_URL="https://raw.githubusercontent.com/chriscarterux/Mothership---Core/$VERSION"

# Download checksums first
echo "Downloading checksums..."
curl -fsSL "$BASE_URL/checksums.sha256" -o /tmp/mothership-checksums.sha256 2>/dev/null || {
    echo "Warning: No checksums.sha256 found, proceeding without verification"
    touch /tmp/mothership-checksums.sha256
}

echo "Downloading Mothership Core..."
curl -fsSL "$BASE_URL/mothership.md" -o .mothership/mothership.md
EXPECTED=$(awk '$2 == "mothership.md" {print $1}' /tmp/mothership-checksums.sha256)
verify_checksum ".mothership/mothership.md" "$EXPECTED"

if [ "$INSTALL_TYPE" == "full" ]; then
    echo "Downloading specialized agents..."
    mkdir -p .mothership/agents
    for agent in cipher vector cortex sentinel; do
        curl -fsSL "$BASE_URL/agents/${agent}.md" -o ".mothership/agents/${agent}.md"
        EXPECTED=$(awk -v f="agents/${agent}.md" '$2 == f {print $1}' /tmp/mothership-checksums.sha256)
        verify_checksum ".mothership/agents/${agent}.md" "$EXPECTED"
    done
fi

# Download loop script
curl -fsSL "$BASE_URL/mothership.sh" -o mothership.sh
EXPECTED=$(awk '$2 == "mothership.sh" {print $1}' /tmp/mothership-checksums.sha256)
verify_checksum "mothership.sh" "$EXPECTED"
chmod +x mothership.sh

# Cleanup
rm -f /tmp/mothership-checksums.sha256

# Create initial checkpoint
cat > .mothership/checkpoint.md << 'EOF'
phase: ready
project: null
branch: null
story: null
EOF

# Add to .gitignore
if [ -f .gitignore ]; then
    if ! grep -q ".mothership/progress.md" .gitignore; then
        echo "" >> .gitignore
        echo "# Mothership Core" >> .gitignore
        echo ".mothership/progress.md" >> .gitignore
    fi
else
    echo "# Mothership Core" > .gitignore
    echo ".mothership/progress.md" >> .gitignore
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
