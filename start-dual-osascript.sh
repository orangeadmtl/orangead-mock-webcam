#!/bin/bash
# osascript wrapper for camera permissions
# Based on: https://stackoverflow.com/questions/74933386

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}OrangeAd Mock Webcam - osascript Wrapper${NC}"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Load configuration from config.conf
CONFIG_FILE="$SCRIPT_DIR/config.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: Configuration file not found: $CONFIG_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}Loading configuration from: $CONFIG_FILE${NC}"

# Source the configuration file (simple and fast)
source "$CONFIG_FILE"

# Validate loaded configuration
if [ -z "$CAMERA_INDEX" ] || [ -z "$RTSP_PORT" ] || [ -z "$FRAME_DIR" ] || [ -z "$FRAME_FPS" ] || [ -z "$STREAM_NAME" ] || [ -z "$INPUT_FPS" ] || [ -z "$VIDEO_SIZE" ]; then
    echo -e "${RED}Error: Failed to load required configuration values${NC}"
    echo -e "${YELLOW}Loaded values:${NC}"
    echo -e "  CAMERA_INDEX: '$CAMERA_INDEX'"
    echo -e "  RTSP_PORT: '$RTSP_PORT'"
    echo -e "  FRAME_DIR: '$FRAME_DIR'"
    echo -e "  FRAME_FPS: '$FRAME_FPS'"
    echo -e "  STREAM_NAME: '$STREAM_NAME'"
    echo -e "  INPUT_FPS: '$INPUT_FPS'"
    echo -e "  VIDEO_SIZE: '$VIDEO_SIZE'"
    exit 1
fi

echo -e "${BLUE}Configuration loaded: $VIDEO_SIZE @ ${INPUT_FPS}fps → RTSP:${RTSP_PORT} + Frames:${FRAME_DIR}@${FRAME_FPS}fps${NC}"

# Make sure start-dual.sh is executable
chmod +x start-dual.sh

echo -e "${BLUE}Launching via osascript for camera permissions...${NC}"

# Use osascript with Terminal for camera permissions - Terminal window will remain
osascript << OSASCRIPT_EOF
tell application "Terminal"
    do script "cd '$SCRIPT_DIR' && ./start-dual.sh"
end tell
OSASCRIPT_EOF

echo -e "${GREEN}Stream launched: rtsp://localhost:${RTSP_PORT}/${STREAM_NAME}${NC}"
