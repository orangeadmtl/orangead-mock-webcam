#!/bin/bash
# Enhanced Mock Webcam with Dual-Output Support
# Implements dual-pipeline architecture for mock video testing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}OrangeAd Mock Webcam - Dual Output Mode${NC}"
echo -e "${BLUE}Architecture: Video → FFmpeg → [RTSP Stream + Detection Frames]${NC}"

# Configuration
RTSP_PORT=${RTSP_PORT:-8554}
FRAME_DIR=${FRAME_DIR:-"/tmp/webcam"}
FRAME_FPS=${FRAME_FPS:-5}
STREAM_NAME=${STREAM_NAME:-"webcam"}
FRAME_QUALITY=${FRAME_QUALITY:-95}

echo -e "${BLUE}Configuration:${NC}"
echo -e "  RTSP Stream: rtsp://localhost:${RTSP_PORT}/${STREAM_NAME}"
echo -e "  Frame Output: $FRAME_DIR (${FRAME_FPS} FPS)"
echo -e "  Frame Quality: $FRAME_QUALITY"

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

# Create frame output directory
mkdir -p "$FRAME_DIR"
echo -e "${GREEN}✓ Frame directory created: $FRAME_DIR${NC}"

# Start background cleanup process to keep only latest 10000 files
echo -e "${BLUE}Starting background cleanup process...${NC}"
(
    while true; do
        sleep 1
        if [ -d "$FRAME_DIR" ]; then
            # Count files and remove oldest if more than 10000
            file_count=$(find "$FRAME_DIR" -type f -name "*.webp" | wc -l)
            if [ "$file_count" -gt 10000 ]; then
                files_to_remove=$((file_count - 10000))
                find "$FRAME_DIR" -type f -name "*.webp" -printf '%T@ %p\n' | sort -n | head -n "$files_to_remove" | cut -d' ' -f2- | xargs rm -f
            fi
        fi
    done
) &
CLEANUP_PID=$!
echo -e "${GREEN}✓ Background cleanup started (keeping latest 10000 files)${NC}"

# Kill any existing MediaMTX or FFmpeg processes
pkill -f mediamtx 2>/dev/null || true
pkill -f ffmpeg 2>/dev/null || true

echo -e "${BLUE}Starting MediaMTX server...${NC}"
./mediamtx &
MEDIAMTX_PID=$!

# Function to cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}Shutting down services...${NC}"
    kill $MEDIAMTX_PID 2>/dev/null || true
    kill $CLEANUP_PID 2>/dev/null || true
    pkill -f ffmpeg 2>/dev/null || true
    pkill -f mediamtx 2>/dev/null || true
    echo -e "${GREEN}Services stopped${NC}"
}

# Setup signal handlers
trap cleanup EXIT INT TERM

# Wait for MediaMTX to start
echo -e "${BLUE}Waiting for MediaMTX to start...${NC}"
timeout=30
while ! nc -z localhost $RTSP_PORT && [ $timeout -gt 0 ]; do
    sleep 0.5
    timeout=$((timeout - 1))
done

if [ $timeout -eq 0 ]; then
    echo -e "${RED}Error: MediaMTX failed to start within 15 seconds${NC}"
    exit 1
fi

echo -e "${GREEN}✓ MediaMTX started successfully${NC}"

# Start dual-output video stream
echo -e "${BLUE}Starting dual-output video stream...${NC}"
echo -e "${GREEN}RTSP Stream: rtsp://localhost:${RTSP_PORT}/${STREAM_NAME}${NC}"
echo -e "${GREEN}Detection Frames: ${FRAME_DIR}/${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"

# Start dual-output FFmpeg pipeline - matches colleague's Linux pattern
# This creates both RTSP stream (for viewing) and local frames (for AI detection)
ffmpeg \
    -re -stream_loop -1 -i sample.mp4 \
    -filter_complex "[0:v]split=2[rtsp][img]" \
    -map "[rtsp]" \
        -c:v libx264 \
        -preset ultrafast \
        -tune zerolatency \
        -f rtsp rtsp://localhost:${RTSP_PORT}/${STREAM_NAME} \
    -map "[img]" \
        -r $FRAME_FPS \
        -c:v libwebp \
        -preset 2 \
        -quality $FRAME_QUALITY \
        "${FRAME_DIR}/img_%06d.webp" \
    -loglevel error