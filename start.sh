#!/bin/bash

# Check for MediaMTX binary
if [ ! -f "./mediamtx" ]; then
    echo "MediaMTX not found. Run ./setup.sh first."
    exit 1
fi

# Simple RTSP feed script
echo "Starting RTSP stream at rtsp://localhost:8554/webcam"

# Start MediaMTX
./mediamtx &

# Wait for MediaMTX to start
while ! nc -z localhost 8554; do   
  sleep 0.1
done

# Start video stream
ffmpeg -re -stream_loop -1 -i sample.mp4 -c copy -f rtsp rtsp://localhost:8554/webcam -loglevel quiet

# Kill MediaMTX when ffmpeg stops
pkill mediamtx