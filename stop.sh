#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Stopping OrangeAd Mock Webcam Services...${NC}"

# Force kill MediaMTX processes
if pgrep -f mediamtx > /dev/null; then
    pkill -9 -f mediamtx
    echo -e "${GREEN}✓ MediaMTX force killed${NC}"
else
    echo -e "${YELLOW}⚠ No MediaMTX processes found${NC}"
fi

# Force kill FFmpeg processes
if pgrep -f ffmpeg > /dev/null; then
    pkill -9 -f ffmpeg
    echo -e "${GREEN}✓ FFmpeg force killed${NC}"
else
    echo -e "${YELLOW}⚠ No FFmpeg processes found${NC}"
fi

# Clean up any remaining processes
pkill -9 ffmpeg 2>/dev/null || true
pkill -9 mediamtx 2>/dev/null || true

# Check if any processes are still running
if pgrep -f "mediamtx|ffmpeg" >/dev/null 2>&1; then
    echo -e "${RED}Warning: Some processes may still be running${NC}"
    echo "Use 'ps aux | grep -E \"mediamtx|ffmpeg\"' to check"
else
    echo -e "${GREEN}All services stopped successfully${NC}"
fi