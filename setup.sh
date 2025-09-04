#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}MediaMTX Setup Script${NC}"
echo "Downloading latest MediaMTX release..."

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# Map architecture names to match MediaMTX release naming
case "$ARCH" in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64|arm64)
        ARCH="arm64"
        ;;
    armv7l)
        ARCH="armv7"
        ;;
    armv6l)
        ARCH="armv6"
        ;;
    *)
        echo -e "${RED}Error: Unsupported architecture: $ARCH${NC}"
        exit 1
        ;;
esac

# Map OS names
case "$OS" in
    linux)
        OS="linux"
        FILE_EXT="tar.gz"
        ;;
    darwin)
        OS="darwin"
        FILE_EXT="tar.gz"
        ;;
    *)
        echo -e "${RED}Error: Unsupported operating system: $OS${NC}"
        exit 1
        ;;
esac

echo "Detected OS: $OS, Architecture: $ARCH"

# Get latest release info from GitHub API
echo "Fetching latest release information..."
LATEST_RELEASE=$(curl -s https://api.github.com/repos/bluenviron/mediamtx/releases/latest)
VERSION=$(echo "$LATEST_RELEASE" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$VERSION" ]; then
    echo -e "${RED}Error: Could not fetch latest version${NC}"
    exit 1
fi

echo "Latest version: $VERSION"

# Check if MediaMTX already exists and get its version
if [ -f "./mediamtx" ]; then
    echo "Checking current MediaMTX version..."
    CURRENT_VERSION=$(./mediamtx --version 2>/dev/null | head -n1 | grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
    echo "Current version: $CURRENT_VERSION"
    
    if [ "$CURRENT_VERSION" = "$VERSION" ]; then
        echo -e "${GREEN}MediaMTX is already up to date!${NC}"
        exit 0
    elif [ "$CURRENT_VERSION" != "unknown" ]; then
        echo -e "${YELLOW}Updating from $CURRENT_VERSION to $VERSION${NC}"
    fi
fi

# Construct download URL
FILENAME="mediamtx_${VERSION}_${OS}_${ARCH}.${FILE_EXT}"
DOWNLOAD_URL="https://github.com/bluenviron/mediamtx/releases/download/${VERSION}/${FILENAME}"

echo "Download URL: $DOWNLOAD_URL"

# Download the file
echo "Downloading $FILENAME..."
if ! curl -L -o "/tmp/$FILENAME" "$DOWNLOAD_URL"; then
    echo -e "${RED}Error: Failed to download MediaMTX${NC}"
    exit 1
fi

# Extract the file to current directory
echo "Extracting..."
tar -xzf "/tmp/$FILENAME" -C .

# Clean up
rm "/tmp/$FILENAME"
rm -f LICENSE

# Make mediamtx executable
if [ -f "mediamtx" ]; then
    chmod +x mediamtx
else
    echo -e "${RED}Error: mediamtx binary not found after extraction${NC}"
    exit 1
fi

echo -e "${GREEN}Success!${NC} MediaMTX $VERSION has been installed to current directory"
echo "To run MediaMTX: ./mediamtx"

# Check if config file exists  
if [ -f "setup" ]; then
    echo -e "${YELLOW}Configuration file found: setup${NC}"
else
    echo -e "${YELLOW}No configuration file found. MediaMTX will use default settings.${NC}"
fi