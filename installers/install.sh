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

echo -e "${BLUE}⬇️  Downloading cmdop...${NC}"

# Create temp directory in a safe location
# This works regardless of current directory (even if it's read-only like /)
if [ -n "$TMPDIR" ]; then
    # macOS/BSD sets TMPDIR
    TMP_BASE="$TMPDIR"
elif [ -d "/tmp" ] && [ -w "/tmp" ]; then
    # Linux/Unix standard
    TMP_BASE="/tmp"
else
    # Fallback to home directory
    TMP_BASE="$HOME"
fi

TMP_DIR=$(mktemp -d "${TMP_BASE}/cmdop-install.XXXXXX" 2>/dev/null || mktemp -d)
cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# Verify temp directory is writable
if [ ! -w "$TMP_DIR" ]; then
    echo -e "${RED}❌ Cannot create writable temporary directory${NC}"
    echo ""
    echo "💡 Try running from your home directory:"
    echo "   cd ~"
    echo "   curl -sSL $DOWNLOAD_URL | bash"
    exit 1
fi

BINARY_PATH="$TMP_DIR/$BINARY_NAME"

# Download with animated spinner
download_with_spinner() {
    local url=$1
    local output=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    # Start download in background
    curl -fL "$url" -o "$output" 2>/dev/null &
    local pid=$!

    # Show spinner while downloading
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 10 ))
        printf "\r   ${GREEN}${spin:$i:1}${NC} Downloading..." >&2
        sleep 0.1
    done

    wait $pid
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        # Show success with file size
        local size_mb=$(ls -l "$output" 2>/dev/null | awk '{printf "%.1f", $5/1048576}')
        printf "\r   ${GREEN}✓${NC} Downloaded (${size_mb} MB)                    \n" >&2
    fi

    return $exit_code
}

if command_exists curl; then
    download_with_spinner "$DOWNLOAD_URL" "$BINARY_PATH" || {
        CURL_EXIT=$?
        echo ""
        echo -e "${RED}❌ Failed to download cmdop${NC}"
        echo ""
        if [ $CURL_EXIT -eq 56 ]; then
            echo "💡 Network error (timeout or connection issue)"
            echo "   Please check your internet connection and try again"
        else
            echo "💡 Try downloading manually:"
            echo "   curl -L $DOWNLOAD_URL -o cmdop && chmod +x cmdop && sudo mv cmdop /usr/local/bin/"
        fi
        exit 1
    }
elif command_exists wget; then
    # wget fallback with spinner
    spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    wget -q "$DOWNLOAD_URL" -O "$BINARY_PATH" &
    pid=$!
    i=0
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 10 ))
        printf "\r   ${GREEN}${spin:$i:1}${NC} Downloading..."
        sleep 0.1
    done
    wait $pid || {
        echo ""
        echo -e "${RED}❌ Failed to download cmdop${NC}"
        exit 1
    }
    size_mb=$(ls -l "$BINARY_PATH" 2>/dev/null | awk '{printf "%.1f", $5/1048576}')
    printf "\r   ${GREEN}✓${NC} Downloaded (${size_mb} MB)                    \n"
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
    echo -e "   ${GREEN}cmdop login${NC}          Login to your account"
    echo -e "   ${GREEN}cmdop agent start${NC}    Run agent in background"
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
