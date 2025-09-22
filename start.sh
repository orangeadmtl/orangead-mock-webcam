#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}OrangeAd Mock Webcam Service${NC}"

# Check for MediaMTX binary
if [ ! -f "./mediamtx" ]; then
    echo -e "${RED}Error: MediaMTX not found. Run ./setup.sh first.${NC}"
    exit 1
fi

# Check for sample video
if [ ! -f "./sample.mp4" ]; then
    echo -e "${RED}Error: sample.mp4 not found.${NC}"
    exit 1
fi

# Check for ffmpeg
if ! command -v ffmpeg >/dev/null 2>&1; then
    echo -e "${RED}Error: ffmpeg not found. Run ./setup.sh to install dependencies.${NC}"
    exit 1
fi

# Check for netcat
if ! command -v nc >/dev/null 2>&1; then
    echo -e "${RED}Error: netcat not found. Run ./setup.sh to install dependencies.${NC}"
    exit 1
fi

# Kill any existing MediaMTX processes
pkill -f mediamtx 2>/dev/null || true

echo -e "${BLUE}Starting MediaMTX server...${NC}"
./mediamtx &
MEDIAMTX_PID=$!

# Function to cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}Shutting down services...${NC}"
    kill $MEDIAMTX_PID 2>/dev/null || true
    pkill -f ffmpeg 2>/dev/null || true
    pkill -f mediamtx 2>/dev/null || true
    echo -e "${GREEN}Services stopped${NC}"
}

# Setup signal handlers
trap cleanup EXIT INT TERM

# Wait for MediaMTX to start
echo -e "${BLUE}Waiting for MediaMTX to start...${NC}"
timeout=30
while ! nc -z localhost 8554 && [ $timeout -gt 0 ]; do
    sleep 0.5
    timeout=$((timeout - 1))
done

if [ $timeout -eq 0 ]; then
    echo -e "${RED}Error: MediaMTX failed to start within 15 seconds${NC}"
    exit 1
fi

echo -e "${GREEN}✓ MediaMTX started successfully${NC}"
echo -e "${BLUE}Starting video stream...${NC}"
echo -e "${GREEN}RTSP Stream: rtsp://localhost:8554/webcam${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"

# Start video stream
ffmpeg -re -stream_loop -1 -i sample.mp4 -c copy -f rtsp rtsp://localhost:8554/webcam -loglevel error