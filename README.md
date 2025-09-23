# OrangeAd Mock Webcam

A mock webcam service using MediaMTX and FFmpeg to provide RTSP video streaming for testing and development.

## Features

- **Dual-Output Architecture**: Supports both RTSP streaming and local frame generation for optimal AI detection
- **RTSP Streaming**: Streams a sample video on `rtsp://localhost:8554/webcam`
- **Local Frame Generation**: Creates WebP frames in `/tmp/webcam/` for low-latency AI detection
- **Automatic Dependency Management**: Installs required dependencies on macOS (Homebrew, FFmpeg, netcat)
- **Robust Service Management**: Proper startup, shutdown, and error handling
- **Cross-Platform**: Supports Linux and macOS (with enhanced macOS support)

## Quick Start

### 1. Setup
```bash
./setup.sh
```

This will:
- Install MediaMTX
- On macOS: Install Homebrew (if needed), FFmpeg, and netcat
- Verify all dependencies

### 2. Start Service

**Standard Mode (RTSP Only)**:
```bash
./start.sh
```

**Dual-Output Mode (RTSP + Local Frames)**:
```bash
./start-dual.sh
```

### 3. Stop Service
```bash
./stop.sh
```

## Usage

### Testing the Stream
```bash
# Using mpv
mpv rtsp://localhost:8554/webcam

# Using VLC
vlc rtsp://localhost:8554/webcam

# Using ffplay
ffplay rtsp://localhost:8554/webcam
```

### Integration with oaTracker

**For Standard Mode (RTSP)**:
Configure oaTracker to use the RTSP stream:
```yaml
default_yolo_source: "rtsp://localhost:8554/webcam"
```

**For Dual-Output Mode (Recommended)**:
Configure oaTracker to use local frames for optimal performance:
```yaml
default_yolo_source: "/tmp/webcam/"
```

The dual-output mode provides:
- **<100ms latency** for AI detection via local frames
- **Live RTSP stream** for viewing and recording
- **Automatic frame cleanup** to prevent disk space issues

## Requirements

### macOS
- macOS 10.15+ (automatically handled by setup script)
- Internet connection for downloading dependencies

### Linux
- `curl` and `tar` for MediaMTX installation
- `ffmpeg` must be installed separately
- `netcat` for port checking

## Files

- `setup.sh` - Setup script with dependency management
- `start.sh` - Start the mock webcam service
- `stop.sh` - Stop all services
- `mediamtx.yml` - MediaMTX configuration
- `sample.mp4` - Sample video file for streaming

## Configuration

The MediaMTX configuration can be customized by editing `mediamtx.yml`. Key settings:

- **RTSP Port**: Default 8554
- **Stream Path**: `/webcam`
- **Video Quality**: Configured in FFmpeg parameters

## Troubleshooting

### Port Already in Use
```bash
# Check what's using port 8554
lsof -i :8554

# Kill existing processes
./stop.sh
```

### Dependencies Missing
```bash
# Re-run setup to install dependencies
./setup.sh
```

### Stream Not Working
1. Check if MediaMTX is running: `ps aux | grep mediamtx`
2. Check if FFmpeg is running: `ps aux | grep ffmpeg`
3. Test port connectivity: `nc -z localhost 8554`

## Development

For integration with OrangeAd projects, deploy to `~/orangead/mock-webcam/` on target devices:

```bash
# Clone to standard location
cd ~/orangead
git clone https://github.com/orangeadmtl/orangead-mock-webcam.git mock-webcam
cd mock-webcam
./setup.sh
./start.sh
```

## License

Part of the OrangeAd ecosystem. See main project documentation for licensing.