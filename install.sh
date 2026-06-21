#!/usr/bin/env bash
set -e

# Installation script for gvu (Go Module Vanity URLs CLI)
# Supports Linux, macOS, and Windows (via WSL/Git Bash)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Repository information
REPO="gomodvanityurls/gvu"
GITHUB_BASE="https://github.com/${REPO}"
API_BASE="https://api.github.com/repos/${REPO}"

# Version to install (default: latest)
VERSION="${VERSION:-latest}"

# Installation directory
# Default to /usr/local/bin for system-wide install, or ~/.local/bin for user-level
if [ "$EUID" -eq 0 ]; then
    INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
else
    INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
fi

# Binary name
BINARY_NAME="gvu"

# Detect platform
detect_platform() {
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch=$(uname -m)

    # Detect WSL (Windows Subsystem for Linux)
    if [ "$os" = "linux" ] && grep -qi "microsoft\|wsl" /proc/version 2>/dev/null; then
        IS_WSL=true
        echo -e "${YELLOW}Detected WSL (Windows Subsystem for Linux)${NC}"
        echo -e "${GREEN}Using Linux binary for WSL${NC}"
    else
        IS_WSL=false
    fi

    case "$os" in
        linux)
            ;;
        darwin)
            ;;
        msys*|mingw*|cygwin*)
            # Native Windows shell (Git Bash, MSYS2, Cygwin)
            # Cannot run Linux binaries here
            echo -e "${YELLOW}Detected Windows shell environment${NC}"
            echo ""
            echo -e "${YELLOW}Options:${NC}"
            echo "  1. Use WSL/WSL2 (recommended):"
            echo "     wsl"
            echo "     curl -fsSL https://gomodvanityurls.com/install.sh | bash"
            echo ""
            echo "  2. Download Windows binary manually:"
            echo "     Visit: ${GITHUB_BASE}/releases/latest"
            echo "     Download: gvu-windows-amd64.exe"
            echo "     Rename to gvu.exe and add to PATH"
            echo ""
            echo -e "${RED}Error: This script requires WSL for Windows installation${NC}"
            exit 1
            ;;
        *)
            echo -e "${RED}Error: Unsupported OS: $os${NC}"
            exit 1
            ;;
    esac

    case "$arch" in
        x86_64|amd64)
            arch="amd64"
            ;;
        i386|i686)
            arch="386"
            ;;
        aarch64|arm64)
            arch="arm64"
            ;;
        armv7l)
            arch="arm"
            ;;
        *)
            echo -e "${RED}Error: Unsupported architecture: $arch${NC}"
            exit 1
            ;;
    esac

    echo "${os}-${arch}"
}

# Get latest version from GitHub API
get_latest_version() {
    if [ "$VERSION" != "latest" ]; then
        echo "$VERSION"
        return
    fi

    local version
    version=$(curl -s "${API_BASE}/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

    if [ -z "$version" ]; then
        echo -e "${RED}Error: Failed to fetch latest version${NC}"
        exit 1
    fi

    echo "$version"
}

# Download and install binary
install_binary() {
    local version="$1"
    local platform="$2"
    local download_url="${GITHUB_BASE}/releases/download/${version}/gvu-${platform}"

    echo -e "${GREEN}Installing gvu ${version} for ${platform}...${NC}"

    # Create temporary directory
    local tmp_dir=$(mktemp -d)
    trap "rm -rf $tmp_dir" EXIT

    # Download binary
    echo -e "${YELLOW}Downloading from ${download_url}${NC}"
    if ! curl -fsSL "$download_url" -o "$tmp_dir/gvu"; then
        echo -e "${RED}Error: Failed to download binary${NC}"
        exit 1
    fi

    # Make binary executable
    chmod +x "$tmp_dir/gvu"

    # Create install directory if it doesn't exist
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${YELLOW}Creating directory: $INSTALL_DIR${NC}"
        mkdir -p "$INSTALL_DIR"
    fi

    # Move binary to install directory
    mv "$tmp_dir/gvu" "${INSTALL_DIR}/${BINARY_NAME}"

    echo -e "${GREEN}Successfully installed to ${INSTALL_DIR}/${BINARY_NAME}${NC}"
}

# Verify installation
verify_installation() {
    if ! command -v "$BINARY_NAME" &> /dev/null; then
        echo -e "${YELLOW}Warning: ${BINARY_NAME} not found in PATH${NC}"
        echo -e "${YELLOW}Add ${INSTALL_DIR} to your PATH:${NC}"
        echo ""
        echo "  export PATH=\"\$PATH:${INSTALL_DIR}\""
        echo ""
        echo "Then restart your shell or run:"
        echo "  source ~/.bashrc  # or ~/.zshrc"
        return 1
    fi

    echo -e "${GREEN}Installation verified!${NC}"
    "${BINARY_NAME}" version
}

# Main installation flow
main() {
    echo -e "${GREEN}=== gvu Installation Script ===${NC}"
    echo ""

    # Detect platform
    PLATFORM=$(detect_platform)
    echo "Detected platform: ${PLATFORM}"

    # Get version
    VERSION=$(get_latest_version)
    echo "Version to install: ${VERSION}"
    echo ""

    # Install binary
    install_binary "$VERSION" "$PLATFORM"
    echo ""

    # Verify installation
    verify_installation

    echo ""
    echo -e "${GREEN}Installation complete!${NC}"

    # WSL-specific tips
    if [ "$IS_WSL" = "true" ]; then
        echo ""
        echo -e "${YELLOW}WSL Tips:${NC}"
        echo "  - gvu is installed in WSL's Linux filesystem"
        echo "  - To use from Windows PowerShell, add WSL to PATH or use:"
        echo "    wsl gvu --help"
    fi

    echo ""
    echo "To get started:"
    echo "  gvu --help"
    echo ""
    echo "For more information:"
    echo "  ${GITHUB_BASE}"
}

# Run main
main "$@"
