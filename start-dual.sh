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

# Load configuration from config.conf or use environment variables as fallback
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.conf"

# Load configuration values with fallbacks to environment variables or defaults
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${BLUE}Loading configuration from: $CONFIG_FILE${NC}"
    # Source the config file, but preserve any existing environment variables
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ $key =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue

        # Remove quotes from value if present
        value=$(echo "$value" | sed 's/^"//;s/"$//')

        # Only set if not already set in environment
        eval "export $key=\${$key:-$value}"
    done < "$CONFIG_FILE"
else
    echo -e "${YELLOW}Config file not found, using environment variables or defaults${NC}"
fi

# Final fallback to hardcoded defaults
CAMERA_INDEX=${CAMERA_INDEX:-"0"}
RTSP_PORT=${RTSP_PORT:-8554}
FRAME_DIR=${FRAME_DIR:-"/tmp/webcam"}
FRAME_FPS=${FRAME_FPS:-5}
STREAM_NAME=${STREAM_NAME:-"webcam"}
FRAME_QUALITY=${FRAME_QUALITY:-95}
INPUT_FPS=${INPUT_FPS:-10}
VIDEO_SIZE=${VIDEO_SIZE:-"1280x720"}
MAX_FILES=${MAX_FILES:-10000}
CLEANUP_INTERVAL=${CLEANUP_INTERVAL:-1}
STARTUP_TIMEOUT=${STARTUP_TIMEOUT:-30}

echo -e "${BLUE}Configuration:${NC}"
echo -e "  Input: $CAMERA_INDEX"
echo -e "  Resolution: $VIDEO_SIZE @ ${INPUT_FPS}fps"
echo -e "  RTSP Stream: rtsp://localhost:${RTSP_PORT}/${STREAM_NAME}"
echo -e "  Frame Output: $FRAME_DIR (${FRAME_FPS} FPS)"
echo -e "  Frame Quality: $FRAME_QUALITY"

# Check for MediaMTX binary and auto-setup if missing
if [ ! -f "./mediamtx" ]; then
    echo -e "${YELLOW}MediaMTX binary not found. Running automatic setup...${NC}"
    if [ -f "./setup.sh" ]; then
        ./setup.sh
        if [ ! -f "./mediamtx" ]; then
            echo -e "${RED}Error: Setup failed to install MediaMTX binary.${NC}"
            exit 1
        fi
        echo -e "${GREEN}✓ MediaMTX installed successfully${NC}"
    else
        echo -e "${RED}Error: setup.sh not found. Cannot auto-install MediaMTX.${NC}"
        exit 1
    fi
fi

# Input source validation
if [[ -f "$CAMERA_INDEX" ]]; then
    echo -e "${GREEN}Using video file: $CAMERA_INDEX${NC}"
else
    echo -e "${GREEN}Using camera device: $CAMERA_INDEX${NC}"
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

# Start background cleanup process to keep only latest N files
echo -e "${BLUE}Starting background cleanup process (keeping latest $MAX_FILES files)...${NC}"
(
    while true; do
        sleep $CLEANUP_INTERVAL
        if [ -d "$FRAME_DIR" ]; then
            # Count files and remove oldest if more than MAX_FILES
            file_count=$(find "$FRAME_DIR" -type f -name "*.webp" | wc -l)
            if [ "$file_count" -gt "$MAX_FILES" ]; then
                files_to_remove=$((file_count - MAX_FILES))
                find "$FRAME_DIR" -type f -name "*.webp" -printf '%T@ %p\n' | sort -n | head -n "$files_to_remove" | cut -d' ' -f2- | xargs rm -f
            fi
        fi
    done
) &
CLEANUP_PID=$!
echo -e "${GREEN}✓ Background cleanup started (keeping latest $MAX_FILES files)${NC}"

# Kill any existing MediaMTX or FFmpeg processes
pkill -f mediamtx 2>/dev/null || true
pkill -f ffmpeg 2>/dev/null || true

echo -e "${BLUE}Starting MediaMTX server with mediamtx.yml config...${NC}"
./mediamtx mediamtx.yml &
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
echo -e "${BLUE}Waiting for MediaMTX to start (timeout: ${STARTUP_TIMEOUT}s)...${NC}"
timeout=$((STARTUP_TIMEOUT * 2))  # Convert to half-second intervals
while ! nc -z localhost $RTSP_PORT && [ $timeout -gt 0 ]; do
    sleep 0.5
    timeout=$((timeout - 1))
done

if [ $timeout -eq 0 ]; then
    echo -e "${RED}Error: MediaMTX failed to start within ${STARTUP_TIMEOUT} seconds${NC}"
    exit 1
fi

echo -e "${GREEN}✓ MediaMTX started successfully${NC}"

# Start dual-output stream
echo -e "${BLUE}Starting dual-output stream...${NC}"
echo -e "${GREEN}RTSP Stream: rtsp://localhost:${RTSP_PORT}/${STREAM_NAME}${NC}"
echo -e "${GREEN}Detection Frames: ${FRAME_DIR}/${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"

# Determine input arguments based on source type
if [[ -f "$CAMERA_INDEX" ]]; then
    # Video file input
    echo -e "${BLUE}Using video file: $CAMERA_INDEX${NC}"
    INPUT_ARGS="-re -stream_loop -1 -i $CAMERA_INDEX"
else
    # Camera device input
    echo -e "${BLUE}Using camera device: $CAMERA_INDEX${NC}"
    INPUT_ARGS="-f avfoundation -pixel_format uyvy422 -video_size $VIDEO_SIZE -framerate $INPUT_FPS -i $CAMERA_INDEX"
fi

# Start dual-output FFmpeg pipeline
# Creates both RTSP stream (for viewing) and local frames (for AI detection)
ffmpeg \
    $INPUT_ARGS \
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