# OrangeAd Mock Webcam

A mock webcam service using MediaMTX and FFmpeg to provide RTSP video streaming for testing and development.

## Features

- **Automatic Dependency Management**: Installs required dependencies on macOS (Homebrew, FFmpeg, netcat)
- **RTSP Streaming**: Streams a sample video on `rtsp://localhost:8554/webcam`
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
```bash
./start.sh
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

Configure oaTracker to use the mock webcam by setting the video source in `config.yaml`:

```yaml
default_yolo_source: "rtsp://localhost:8554/webcam"
```

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