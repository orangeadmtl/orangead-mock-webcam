#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}OrangeAd Mock Webcam Setup Script${NC}"
echo -e "${BLUE}Setting up MediaMTX and dependencies...${NC}"

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

# macOS-specific dependency management
if [ "$OS" = "darwin" ]; then
    echo -e "${BLUE}Setting up macOS dependencies...${NC}"

    # Check for Homebrew installation
    if ! command -v brew >/dev/null 2>&1; then
        echo -e "${YELLOW}Homebrew not found. Installing Homebrew...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ "$ARCH" == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    else
        echo -e "${GREEN}Homebrew found: $(brew --version | head -1)${NC}"
    fi

    # Install ffmpeg if not present
    if ! command -v ffmpeg >/dev/null 2>&1; then
        echo -e "${YELLOW}FFmpeg not found. Installing via Homebrew...${NC}"
        brew install ffmpeg
        echo -e "${GREEN}FFmpeg installed successfully${NC}"
    else
        echo -e "${GREEN}FFmpeg found: $(ffmpeg -version | head -1 | cut -d' ' -f3)${NC}"
    fi

    # Install netcat if not present (used for port checking)
    if ! command -v nc >/dev/null 2>&1; then
        echo -e "${YELLOW}Netcat not found. Installing via Homebrew...${NC}"
        brew install netcat
        echo -e "${GREEN}Netcat installed successfully${NC}"
    else
        echo -e "${GREEN}Netcat found${NC}"
    fi

    echo -e "${GREEN}macOS dependencies setup complete${NC}"
fi

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
        # Continue with plist generation even if MediaMTX is up to date
        SKIP_DOWNLOAD=true
    elif [ "$CURRENT_VERSION" != "unknown" ]; then
        echo -e "${YELLOW}Updating from $CURRENT_VERSION to $VERSION${NC}"
    fi
fi

# Download and install MediaMTX if needed
if [ "$SKIP_DOWNLOAD" != "true" ]; then
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
fi

echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}✓ MediaMTX $VERSION installed${NC}"
if [ "$OS" = "darwin" ]; then
    echo -e "${GREEN}✓ macOS dependencies configured${NC}"
    echo -e "${GREEN}✓ FFmpeg available${NC}"
    echo -e "${GREEN}✓ Netcat available${NC}"
fi

echo ""
echo -e "${BLUE}Usage:${NC}"
echo "  Start mock webcam: ./start.sh"
echo "  Stop services:     ./stop.sh"
echo "  RTSP stream URL:   rtsp://localhost:8554/webcam"
echo "  Test with:         mpv rtsp://localhost:8554/webcam"

# Generate LaunchAgent plist from template
echo -e "${BLUE}Generating LaunchAgent plist...${NC}"
if [ -f "com.orangead.mock-webcam.plist.template" ]; then
    # Replace ~ with actual home directory path
    HOME_PATH="$HOME"
    sed "s|~|${HOME_PATH}|g" com.orangead.mock-webcam.plist.template > com.orangead.mock-webcam.plist
    echo -e "${GREEN}✓ LaunchAgent plist generated: com.orangead.mock-webcam.plist${NC}"

    # Add to .gitignore if not already present
    if [ ! -f ".gitignore" ] || ! grep -q "com.orangead.mock-webcam.plist" .gitignore; then
        echo "com.orangead.mock-webcam.plist" >> .gitignore
        echo -e "${GREEN}✓ Added plist to .gitignore${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Template file com.orangead.mock-webcam.plist.template not found${NC}"
fi

# Check if config file exists
if [ -f "mediamtx.yml" ]; then
    echo -e "${YELLOW}Configuration file: mediamtx.yml${NC}"
else
    echo -e "${YELLOW}MediaMTX will use default settings${NC}"
fi