#!/bin/bash

# cmdop CLI Installer
# Downloads and installs the cmdop command-line tool
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/markolofsen/cmdop-client/main/installers/install.sh | bash
#
# Or with custom installation directory:
#   curl -sSL https://raw.githubusercontent.com/markolofsen/cmdop-client/main/installers/install.sh | bash -s -- --prefix=$HOME/.local/bin

set -e

# Helper function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BINARY_NAME="cmdop"
GITHUB_REPO="markolofsen/cmdop-client"
BASE_URL="https://github.com/${GITHUB_REPO}/releases/latest/download"

# Default installation prefix
INSTALL_PREFIX="/usr/local/bin"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --prefix)
            INSTALL_PREFIX="$2"
            shift 2
            ;;
        --prefix=*)
            INSTALL_PREFIX="${1#*=}"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ASCII Banner
echo -e "${BLUE}"
cat << 'BANNER'
 ██████╗███╗   ███╗██████╗  ██████╗ ██████╗
██╔════╝████╗ ████║██╔══██╗██╔═══██╗██╔══██╗
██║     ██╔████╔██║██║  ██║██║   ██║██████╔╝
██║     ██║╚██╔╝██║██║  ██║██║   ██║██╔═══╝
╚██████╗██║ ╚═╝ ██║██████╔╝╚██████╔╝██║
 ╚═════╝╚═╝     ╚═╝╚═════╝  ╚═════╝ ╚═╝
BANNER
echo -e "${NC}"

# Detect OS and Arch
OS="$(uname -s)"
ARCH="$(uname -m)"

case "${OS}" in
    Linux*)     OS=linux;;
    Darwin*)    OS=darwin;;
    *)
        echo -e "${RED}❌ Unsupported OS: ${OS}${NC}"
        echo "   Supported: Linux, macOS"
        exit 1
        ;;
esac

case "${ARCH}" in
    x86_64)    ARCH=amd64;;
    arm64)     ARCH=arm64;;
    aarch64)   ARCH=arm64;;
    *)
        echo -e "${RED}❌ Unsupported Architecture: ${ARCH}${NC}"
        echo "   Supported: amd64, arm64"
        exit 1
        ;;
esac

echo -e "${BLUE}💻 Detected: $OS/$ARCH${NC}"

# Construct Download URL
BINARY_FILE="$BINARY_NAME-$OS-$ARCH"
DOWNLOAD_URL="$BASE_URL/$BINARY_FILE"

echo -e "${BLUE}⬇️  Downloading from: $DOWNLOAD_URL${NC}"

# Create temp directory
TMP_DIR=$(mktemp -d)
cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

BINARY_PATH="$TMP_DIR/$BINARY_NAME"

# Download binary
if command_exists curl; then
    curl -fL --progress-bar "$DOWNLOAD_URL" -o "$BINARY_PATH" || {
        echo -e "${RED}❌ Failed to download cmdop${NC}"
        echo ""
        echo "💡 Try downloading manually:"
        echo "   curl -L $DOWNLOAD_URL -o cmdop"
        echo "   chmod +x cmdop"
        echo "   sudo mv cmdop /usr/local/bin/"
        exit 1
    }
elif command_exists wget; then
    wget --progress=bar:force "$DOWNLOAD_URL" -O "$BINARY_PATH" 2>&1 || {
        echo -e "${RED}❌ Failed to download cmdop${NC}"
        exit 1
    }
else
    echo -e "${RED}❌ Error: curl or wget is required${NC}"
    exit 1
fi

# Make binary executable
chmod +x "$BINARY_PATH"

# Install binary
echo -e "${BLUE}📦 Installing to: $INSTALL_PREFIX/$BINARY_NAME${NC}"

# Check if we need sudo
NEED_SUDO=false
if [ ! -w "$INSTALL_PREFIX" ]; then
    NEED_SUDO=true
fi

if [ "$NEED_SUDO" = true ]; then
    if command_exists sudo; then
        sudo mkdir -p "$INSTALL_PREFIX"
        sudo mv "$BINARY_PATH" "$INSTALL_PREFIX/$BINARY_NAME"
        sudo chmod +x "$INSTALL_PREFIX/$BINARY_NAME"
    else
        echo -e "${RED}❌ Installation requires sudo, but sudo is not available${NC}"
        echo ""
        echo "💡 Try installing to a user directory:"
        echo "   curl -L https://api.cmdop.com/media/cmdop_cli/install.sh | sh -s -- --prefix=\$HOME/.local/bin"
        exit 1
    fi
else
    mkdir -p "$INSTALL_PREFIX"
    mv "$BINARY_PATH" "$INSTALL_PREFIX/$BINARY_NAME"
fi

echo ""
echo -e "${GREEN}✅ cmdop CLI installed successfully!${NC}"
echo ""

# Create default configuration
CONFIG_DIR="$HOME/.config/cmdop"
CONFIG_FILE="$CONFIG_DIR/config.yaml"

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${BLUE}⚙️  Creating default configuration...${NC}"
    mkdir -p "$CONFIG_DIR"

    cat > "$CONFIG_FILE" << 'EOF'
# cmdop CLI Configuration
mode: prod
log_level: warn
log_format: console

servers:
  dev:
    host: localhost
    port: 50051
    http_host: localhost
    http_port: 8000
    use_tls: false
  prod:
    host: grpc.cmdop.com
    port: 443
    http_host: api.cmdop.com
    http_port: 443
    use_tls: true
EOF

    echo -e "${GREEN}✅ Configuration created at: $CONFIG_FILE${NC}"
    echo ""
fi

# Verify installation and show quick start
if command_exists cmdop; then
    # Get installed version
    INSTALLED_VERSION=$(cmdop version 2>/dev/null | head -1 | sed 's/CMDOP CLI version //' || echo "unknown")

    echo -e "${GREEN}🎉 cmdop v${INSTALLED_VERSION} installed successfully!${NC}"
    echo ""
    echo -e "${BLUE}🚀 Quick Start:${NC}"
    echo ""
    echo -e "   ${GREEN}cmdop auth login${NC}     Login to your account"
    echo -e "   ${GREEN}cmdop connect${NC}        Start terminal session"
    echo -e "   ${GREEN}cmdop --help${NC}         Show all commands"
    echo ""
else
    echo -e "${YELLOW}⚠️  cmdop was installed but is not in your PATH${NC}"
    echo ""
    echo "Add $INSTALL_PREFIX to your PATH:"

    SHELL_NAME=$(basename "$SHELL")
    case "$SHELL_NAME" in
        bash)
            echo "  echo 'export PATH=\"$INSTALL_PREFIX:\$PATH\"' >> ~/.bashrc"
            echo "  source ~/.bashrc"
            ;;
        zsh)
            echo "  echo 'export PATH=\"$INSTALL_PREFIX:\$PATH\"' >> ~/.zshrc"
            echo "  source ~/.zshrc"
            ;;
        *)
            echo "  export PATH=\"$INSTALL_PREFIX:\$PATH\""
            ;;
    esac
fi

echo ""
