#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Stopping OrangeAd Mock Webcam Services...${NC}"

# Kill MediaMTX processes
if pkill -f mediamtx 2>/dev/null; then
    echo -e "${GREEN}✓ MediaMTX stopped${NC}"
else
    echo -e "${YELLOW}⚠ No MediaMTX processes found${NC}"
fi

# Kill FFmpeg processes
if pkill -f ffmpeg 2>/dev/null; then
    echo -e "${GREEN}✓ FFmpeg stopped${NC}"
else
    echo -e "${YELLOW}⚠ No FFmpeg processes found${NC}"
fi

# Check if any processes are still running
if pgrep -f "mediamtx|ffmpeg" >/dev/null 2>&1; then
    echo -e "${RED}Warning: Some processes may still be running${NC}"
    echo "Use 'ps aux | grep -E \"mediamtx|ffmpeg\"' to check"
else
    echo -e "${GREEN}All services stopped successfully${NC}"
fi