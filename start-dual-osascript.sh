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

# Fixed configuration for 1280x720@10fps
export CAMERA_INDEX="0"
export RTSP_PORT="8554"
export FRAME_DIR="/tmp/webcam"
export FRAME_FPS="5"
export STREAM_NAME="webcam"
export INPUT_FPS="10"
export VIDEO_SIZE="1280x720"

echo -e "${BLUE}Configuration: $VIDEO_SIZE @ ${INPUT_FPS}fps${NC}"

cd "$SCRIPT_DIR"

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
