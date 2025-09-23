#!/bin/bash


# Install Tesseract if not present
if ! command -v tesseract &> /dev/null; then
    echo "Installing Tesseract OCR..."

    # Detect platform
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt update && sudo apt install -y tesseract-ocr
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - check if we have brew
        if command -v brew &> /dev/null; then
            brew install tesseract
        else
            echo "Homebrew not found. Please install Homebrew first or install Tesseract manually."
            exit 1
        fi
    else
        echo "Unsupported platform: $OSTYPE"
        exit 1
    fi
fi

# Check for MediaMTX binary
if [ ! -f "./mediamtx" ]; then
    echo "MediaMTX not found. Run ./setup.sh first."
    exit 1
fi

# Simple RTSP feed script
echo "Latency test"

# Start MediaMTX
./mediamtx &

# Wait for MediaMTX to start
while ! nc -z localhost 8554; do   
  sleep 0.1
done

sleep 1;

(while true; do date +%s%3N > /tmp/timestamp2.txt; mv -f /tmp/timestamp2.txt /tmp/timestamp.txt > /dev/null 2>&1;  sleep 0.1; done) &

TIMESTAMP_PID=$?

sleep 1;
ffmpeg -f lavfi -i color=white:size=120x20:rate=600 -vf "drawtext=fontcolor=black:fontsize=12:x=(w-tw)/2:y=(h-th)/2:textfile=/tmp/timestamp.txt:reload=1" -vb 20M -r 600 -f rtsp rtsp://localhost:8554/webcam  -loglevel quiet &

FFMPEG_PID=$?

sleep 1;

mpv rtsp://localhost:8554/webcam --input-ipc-server=/tmp/mpvsocket &

sleep 1;
MPV_PID=$?



get_measurement () {
  LOCAL_NOW=$(date +%s%3N)

  echo "screenshot-to-file \"/tmp/screenshot-$LOCAL_NOW.png\"" | socat - /tmp/mpvsocket

  echo "got file /tmp/screenshot-$LOCAL_NOW.png"

  CAM_NOW=$(tesseract /tmp/screenshot-$LOCAL_NOW.png stdout -c tessedit_char_whitelist=0123456789)

  echo OCR RESULT: $CAM_NOW

  DIFF=$(expr  $LOCAL_NOW - $CAM_NOW)

  echo $DIFF
    sleep 1;
}

get_measurement

get_measurement

get_measurement
get_measurement
get_measurement
get_measurement
get_measurement
get_measurement
get_measurement
get_measurement
get_measurement
get_measurement
get_measurement
get_measurement
get_measurement
get_measurement
get_measurement
get_measurement
get_measurement
get_measurement
get_measurement
get_measurement
get_measurement
get_measurement
get_measurement
get_measurement
get_measurement
get_measurement
get_measurement

sleep 5

kill $MPV_PID;
kill $TIMESTAMP_PID;

sleep 5
# Start video stream
#ffmpeg -re -stream_loop -1 -i sample.mp4 -vf drawtext=fontfile=arial.ttf:text=%{localtime.%X.%N}:fontcolor=white:x=7:y=7 -f rtsp rtsp://localhost:8554/webcam1

# Kill MediaMTX when ffmpeg stops
pkill mediamtx


