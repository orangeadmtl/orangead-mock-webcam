# OrangeAd Mock Webcam - Integration & Deployment Guide

## Quick Start Guide

### Prerequisites
- **Operating System**: macOS 10.15+ or Ubuntu 18.04+
- **Dependencies**: curl, tar (automatically installed by setup)
- **Hardware**: Minimum 2GB RAM, 1 CPU core
- **Network**: Port 8554 available for RTSP streaming

### Basic Deployment
```bash
# 1. Clone and setup
git clone https://github.com/orangeadmtl/orangead-mock-webcam.git
cd orangead-mock-webcam
./setup.sh

# 2. Start basic service
./start.sh

# 3. Test stream
ffplay rtsp://localhost:8554/webcam
```

### Enhanced Deployment (Recommended)
```bash
# 1. Clone and setup
git clone https://github.com/orangeadmtl/orangead-mock-webcam.git
cd orangead-mock-webcam
./setup.sh

# 2. Configure dual-output mode
cp config.conf.example config.conf
# Edit config.conf with your settings

# 3. Start enhanced service
./start-dual.sh

# 4. Test both outputs
ffplay rtsp://localhost:8554/webcam          # RTSP stream
ls -la /tmp/webcam/                          # Local frames
```

## Detailed Deployment Procedures

### Phase 1: Environment Preparation

#### 1.1 System Requirements Check
```bash
# Check OS version
cat /etc/os-release  # Linux
sw_vers              # macOS

# Check available resources
free -h              # Linux memory
vm_stat              # macOS memory
nproc                # CPU cores
df -h                # Disk space

# Check network ports
netstat -tuln | grep 8554
lsof -i :8554
```

#### 1.2 Dependency Installation
```bash
# Run automated setup
./setup.sh

# Manual dependency verification
which ffmpeg          # Video processing
which nc              # Network utilities
which curl            # Downloads
which tar             # Archive extraction
```

#### 1.3 User Permissions Setup
```bash
# Ensure proper ownership (Linux)
sudo chown -R $USER:$USER /path/to/orangead-mock-webcam

# Set executable permissions
chmod +x *.sh
chmod +x mediamtx

# Create necessary directories
mkdir -p /tmp/webcam
mkdir -p logs
```

### Phase 2: Configuration Management

#### 2.1 Basic Configuration
```bash
# Create configuration from template
cp config.conf.example config.conf

# Edit configuration settings
nano config.conf
```

**Essential Configuration Parameters:**
```bash
# Input source configuration
CAMERA_INDEX="sample.mp4"           # or "0" for camera
VIDEO_SIZE="1280x720"
INPUT_FPS=10

# Output configuration
RTSP_PORT=8554
STREAM_NAME="webcam"
FRAME_DIR="/tmp/webcam"
FRAME_FPS=5

# Performance tuning
FRAME_QUALITY=95
MAX_FILES=10000
CLEANUP_INTERVAL=1
```

#### 2.2 MediaMTX Configuration
```yaml
# mediamtx.yml - Key settings for OrangeAd integration

# RTSP server configuration
rtsp: yes
rtspAddress: :8554
rtspTransports: [udp, multicast, tcp]

# Path configuration for webcam stream
paths:
  webcam:
    source: publisher
    # Optional: Add authentication
    # publishUser: user
    # publishPass: password

# Security settings (production)
authMethod: internal
authInternalUsers:
  - user: orangead
    pass: ${ORANGEAD_PASSWORD}
    ips: ['127.0.0.1', '::1', '100.x.x.x/8']  # Tailscale network
    permissions:
      - action: publish
        path: webcam
      - action: read
        path: webcam
```

#### 2.3 Environment-Specific Configuration

**Development Environment:**
```bash
# config.conf
CAMERA_INDEX="sample.mp4"
VIDEO_SIZE="640x480"
INPUT_FPS=5
FRAME_FPS=2
RTSP_PORT=8554
```

**Staging Environment:**
```bash
# config.conf
CAMERA_INDEX="0"                    # Real camera
VIDEO_SIZE="1280x720"
INPUT_FPS=15
FRAME_FPS=5
RTSP_PORT=8554
```

**Production Environment:**
```bash
# config.conf
CAMERA_INDEX="0"                    # Real camera
VIDEO_SIZE="1920x1080"
INPUT_FPS=30
FRAME_FPS=10
RTSP_PORT=8554
```

### Phase 3: Service Deployment

#### 3.1 Single Service Deployment
```bash
# Start basic RTSP streaming
./start.sh

# Start dual-output mode (recommended)
./start-dual.sh

# Background deployment
nohup ./start-dual.sh > logs/mock-webcam.log 2>&1 &
```

#### 3.2 System Service Integration

**macOS LaunchAgent:**
```bash
# Install as user service
cp com.orangead.mock-webcam.plist ~/Library/LaunchAgents/

# Load the service
launchctl load ~/Library/LaunchAgents/com.orangead.mock-webcam.plist

# Start the service
launchctl start com.orangead.mock-webcam

# Check status
launchctl list | grep mock-webcam
```

**Linux systemd Service:**
```bash
# Create service file
sudo tee /etc/systemd/system/orangead-mock-webcam.service > /dev/null <<EOF
[Unit]
Description=OrangeAd Mock Webcam Service
After=network.target

[Service]
Type=simple
User=orangead
WorkingDirectory=/opt/orangead-mock-webcam
ExecStart=/opt/orangead-mock-webcam/start-dual.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl enable orangead-mock-webcam
sudo systemctl start orangead-mock-webcam

# Check status
sudo systemctl status orangead-mock-webcam
```

#### 3.3 Docker Deployment
```dockerfile
# Dockerfile
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    tar \
    ffmpeg \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Create application directory
WORKDIR /app

# Copy application files
COPY . .

# Setup MediaMTX
RUN ./setup.sh

# Create frame directory
RUN mkdir -p /tmp/webcam

# Expose RTSP port
EXPOSE 8554

# Start service
CMD ["./start-dual.sh"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  orangead-mock-webcam:
    build: .
    ports:
      - "8554:8554"
    volumes:
      - ./config.conf:/app/config.conf
      - /tmp/webcam:/tmp/webcam
      - ./logs:/app/logs
    environment:
      - CAMERA_INDEX=sample.mp4
      - RTSP_PORT=8554
    restart: unless-stopped
```

## Integration with OrangeAd Components

### oaTracker Integration

#### Configuration Setup
```yaml
# oaTracker config.yml
video_sources:
  default_yolo_source: "/tmp/webcam/"  # Local frames (recommended)
  # Alternative: "rtsp://localhost:8554/webcam"

detection_config:
  frame_rate: 5                         # Match FRAME_FPS
  input_format: "webp"                  # Frame format
  frame_dir: "/tmp/webcam/"             # Frame directory
```

#### API Integration
```python
# oaTracker integration example
import requests

# Check mock webcam status
response = requests.get("http://localhost:8080/health")
if response.status_code == 200:
    # Configure tracker to use local frames
    tracker_config = {
        "source_type": "directory",
        "source_path": "/tmp/webcam/",
        "frame_rate": 5
    }
    requests.post("http://localhost:8080/config", json=tracker_config)
```

#### Performance Optimization
```yaml
# Optimized oaTracker configuration
detection:
  input_buffer_size: 10          # Small buffer for low latency
  processing_threads: 2          # Match available CPU
  max_frame_age: 200             # 200ms max frame age

performance:
  gpu_acceleration: false        # Disable for mock testing
  batch_processing: false        # Process frames individually
```

### oaParkingMonitor Integration

#### Configuration Setup
```yaml
# oaParkingMonitor config.yml
camera_config:
  snapshot_source: "/tmp/webcam/"    # Local WebP frames
  snapshot_interval: 200             # 200ms (5 FPS)

detection_config:
  model_path: "models/yolo11m.pt"
  confidence_threshold: 0.5
  input_resolution: [1280, 720]

processing:
  frame_buffer_size: 5
  processing_timeout: 1000           # 1 second
```

#### API Integration
```bash
# Test parking monitor integration
curl -X POST http://localhost:8091/config \
  -H "Content-Type: application/json" \
  -d '{
    "camera": {
      "source_type": "directory",
      "source_path": "/tmp/webcam/",
      "snapshot_interval": 200
    }
  }'

# Check detection results
curl http://localhost:8091/detections
```

### oaDashboard Integration

#### Service Registration
```javascript
// oaDashboard frontend integration
const mockWebcamConfig = {
  name: "Mock Webcam",
  type: "video_source",
  endpoint: "rtsp://localhost:8554/webcam",
  status_endpoint: "http://localhost:8554/api/v1/streams/webcam",
  health_check: {
    interval: 30000,
    timeout: 5000
  }
};

// Register with dashboard
fetch('/api/services/register', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(mockWebcamConfig)
});
```

#### Monitoring Integration
```javascript
// Real-time monitoring
const monitorMockWebcam = async () => {
  const response = await fetch('/api/mock-webcam/status');
  const status = await response.json();

  return {
    stream_active: status.rtsp_active,
    frames_generated: status.frame_count,
    cpu_usage: status.cpu_percent,
    memory_usage: status.memory_mb,
    disk_usage: status.disk_usage_mb
  };
};
```

### oaAnsible Deployment Integration

#### Ansible Playbook
```yaml
# playbook-mock-webcam.yml
---
- name: Deploy OrangeAd Mock Webcam
  hosts: all
  become: yes

  tasks:
    - name: Create orangead user
      user:
        name: orangead
        shell: /bin/bash
        home: /opt/orangead

    - name: Create deployment directory
      file:
        path: /opt/orangead-mock-webcam
        state: directory
        owner: orangead
        group: orangead

    - name: Deploy mock webcam
      git:
        repo: https://github.com/orangeadmtl/orangead-mock-webcam.git
        dest: /opt/orangead-mock-webcam
        version: main
      become_user: orangead

    - name: Run setup script
      command: ./setup.sh
      args:
        chdir: /opt/orangead-mock-webcam
      become_user: orangead

    - name: Configure service
      template:
        src: config.conf.j2
        dest: /opt/orangead-mock-webcam/config.conf
        owner: orangead
        group: orangead
      vars:
        camera_index: "{{ camera_index | default('sample.mp4') }}"
        rtsp_port: "{{ rtsp_port | default(8554) }}"

    - name: Deploy systemd service
      template:
        src: orangead-mock-webcam.service.j2
        dest: /etc/systemd/system/orangead-mock-webcam.service

    - name: Start and enable service
      systemd:
        name: orangead-mock-webcam
        state: started
        enabled: yes
        daemon_reload: yes
```

#### Inventory Configuration
```ini
# inventory/hosts
[mock_webcam_servers]
webcam-dev ansible_host=192.168.1.100 camera_index=sample.mp4
webcam-staging ansible_host=192.168.1.101 camera_index=0
webcam-prod ansible_host=192.168.1.102 camera_index=0 video_size=1920x1080

[mock_webcam_servers:vars]
ansible_user=orangead
rtsp_port=8554
```

## Network Configuration

### Port Configuration
```bash
# Required ports
8554/tcp    # RTSP streaming
1935/tcp    # RTMP (optional)
8888/tcp    # HLS (optional)
8889/tcp    # WebRTC (optional)
8890/tcp    # SRT (optional)

# Port forwarding (if behind NAT)
# Router config: External port 8554 -> Internal device:8554
```

### Firewall Configuration
```bash
# Ubuntu UFW
sudo ufw allow 8554/tcp comment "OrangeAd Mock Webcam RTSP"
sudo ufw allow from 100.64.0.0/10 to any port 8554 comment "Tailscale access"

# CentOS/RHEL firewalld
sudo firewall-cmd --permanent --add-port=8554/tcp
sudo firewall-cmd --permanent --add-source=100.64.0.0/10 --add-port=8554/tcp
sudo firewall-cmd --reload

# macOS (if using built-in firewall)
# System Preferences → Security & Privacy → Firewall → Firewall Options
# Add "mediamtx" and "ffmpeg" to allowed applications
```

### Tailscale Network Integration
```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Connect to Tailscale network
sudo tailscale up

# Enable IP forwarding (for service discovery)
sudo tailscale set --accept-routes

# Test connectivity
tailscale ip               # Get Tailscale IP
ping 100.x.x.x            # Test to other Tailscale devices
```

## Monitoring and Logging

### Log Configuration
```bash
# Enhanced logging setup
mkdir -p logs/{mediamtx,ffmpeg,system}

# MediaMTX logging configuration
# mediamtx.yml
logLevel: info
logDestinations: [stdout, file]
logFile: logs/mediamtx/mediamtx.log
```

### Log Rotation
```bash
# /etc/logrotate.d/orangead-mock-webcam
/opt/orangead-mock-webcam/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 orangead orangead
    postrotate
        systemctl reload orangead-mock-webcam
    endscript
}
```

### Monitoring Setup
```bash
# Basic monitoring script
#!/bin/bash
# monitor.sh

check_service() {
    local service=$1
    local port=$2

    if nc -z localhost $port; then
        echo "[OK] $service is running on port $port"
        return 0
    else
        echo "[FAIL] $service is not responding on port $port"
        return 1
    fi
}

check_resource_usage() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    local memory_usage=$(free -m | awk 'NR==2{printf "%.1f%%", $3*100/$2}')
    local disk_usage=$(df -h /tmp/webcam | awk 'NR==2{print $5}')

    echo "CPU: $cpu_usage, Memory: $memory_usage, Disk: $disk_usage"
}

# Main monitoring loop
while true; do
    echo "=== $(date) ==="
    check_service "MediaMTX" 8554
    check_resource_usage
    echo ""
    sleep 60
done
```

### Health Check Endpoint
```python
# health_check.py
import requests
import socket
import os
from datetime import datetime

def check_rtsp_stream():
    """Check if RTSP stream is accessible"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        result = sock.connect_ex(('localhost', 8554))
        sock.close()
        return result == 0
    except:
        return False

def check_frame_generation():
    """Check if frames are being generated"""
    frame_dir = "/tmp/webcam"
    if not os.path.exists(frame_dir):
        return False

    frames = [f for f in os.listdir(frame_dir) if f.endswith('.webp')]
    return len(frames) > 0

def get_service_status():
    """Get comprehensive service status"""
    return {
        "timestamp": datetime.now().isoformat(),
        "rtsp_active": check_rtsp_stream(),
        "frames_generating": check_frame_generation(),
        "frame_count": len([f for f in os.listdir("/tmp/webcam") if f.endswith('.webp')]) if os.path.exists("/tmp/webcam") else 0,
        "status": "healthy" if check_rtsp_stream() and check_frame_generation() else "unhealthy"
    }

if __name__ == "__main__":
    import json
    print(json.dumps(get_service_status(), indent=2))
```

## Performance Tuning

### FFmpeg Optimization
```bash
# Hardware acceleration (macOS)
ffmpeg -hwaccel videotoolbox -c:v h264_videotoolbox ...

# Hardware acceleration (Linux with Intel)
ffmpeg -hwaccel vaapi -c:v h264_vaapi ...

# CPU optimization
ffmpeg -preset ultrafast -tune zerolatency -threads 2 ...

# Memory optimization
ffmpeg -buffer_size 64k ...
```

### MediaMTX Tuning
```yaml
# mediamtx.yml performance settings
writeQueueSize: 256                    # Reduce from 512
readTimeout: 5s                        # Reduce from 10s
writeTimeout: 5s                       # Reduce from 10s
udpMaxPayloadSize: 1200                # Optimize for network
```

### System Optimization
```bash
# Linux system tuning
echo 'net.core.rmem_max = 2097152' >> /etc/sysctl.conf
echo 'net.core.wmem_max = 2097152' >> /etc/sysctl.conf
sysctl -p

# macOS system tuning
sudo sysctl -w net.inet.udp.recvspace=2097152
sudo sysctl -w net.inet.udp.sendspace=2097152
```

## Troubleshooting Guide

### Common Deployment Issues

#### 1. Port Already in Use
```bash
# Check what's using the port
sudo lsof -i :8554
sudo netstat -tulpn | grep 8554

# Kill conflicting processes
sudo pkill -f mediamtx
sudo pkill -f ffmpeg

# Change port in configuration
sed -i 's/8554/8555/g' config.conf
```

#### 2. FFmpeg Not Found
```bash
# Verify installation
which ffmpeg
ffmpeg -version

# Install FFmpeg
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install ffmpeg

# macOS with Homebrew
brew install ffmpeg

# Manual installation
curl -O https://ffmpeg.org/releases/ffmpeg-4.4.tar.bz2
tar -xjf ffmpeg-4.4.tar.bz2
cd ffmpeg-4.4
./configure --enable-gpl --enable-libx264
make && sudo make install
```

#### 3. MediaMTX Binary Missing
```bash
# Re-run setup script
./setup.sh

# Manual MediaMTX installation
curl -L https://github.com/bluenviron/mediamtx/releases/download/v1.0.0/mediamtx_v1.0.0_linux_amd64.tar.gz | tar -xz
mv mediamtx_v1.0.0_linux_amd64/mediamtx .
chmod +x mediamtx
```

#### 4. Permission Issues
```bash
# Fix file permissions
chmod +x *.sh
chmod +x mediamtx
chown -R $USER:$USER .

# Fix directory permissions
mkdir -p /tmp/webcam
chmod 755 /tmp/webcam
```

### Debugging Procedures

#### 1. Service Status Check
```bash
# Check all processes
ps aux | grep -E "(ffmpeg|mediamtx)"

# Check network connections
netstat -tulpn | grep 8554

# Check system resources
top -p $(pgrep -d',' ffmpeg,mediamtx)
```

#### 2. Stream Testing
```bash
# Test RTSP connection
nc -zv localhost 8554

# Test with FFmpeg
ffprobe -v quiet -print_format json -show_streams rtsp://localhost:8554/webcam

# Test with VLC
vlc rtsp://localhost:8554/webcam --play-and-exit
```

#### 3. Log Analysis
```bash
# MediaMTX logs
tail -f mediamtx.log | grep -E "(error|warn)"

# FFmpeg debug output
./start-dual.sh 2>&1 | tee ffmpeg-debug.log

# System logs
journalctl -u orangead-mock-webcam -f
```

## Security Considerations

### Network Security
```yaml
# Enable MediaMTX authentication
authMethod: internal
authInternalUsers:
  - user: orangead
    pass: "secure_password_here"
    ips: ['127.0.0.1', '::1', '100.x.x.x/8']  # Tailscale only
    permissions:
      - action: publish
        path: webcam
      - action: read
        path: webcam
```

### File System Security
```bash
# Secure frame directory
chmod 750 /tmp/webcam
chown orangead:orangead /tmp/webcam

# Clean up old frames regularly
find /tmp/webcam -name "*.webp" -mtime +1 -delete
```

### Process Security
```bash
# Run as non-root user
useradd -r -s /bin/false orangead

# Limit process resources
ulimit -n 4096  # File descriptors
ulimit -u 100   # User processes
```

## Backup and Recovery

### Configuration Backup
```bash
# Create backup script
#!/bin/bash
# backup.sh

BACKUP_DIR="/opt/backups/mock-webcam"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup configurations
tar -czf $BACKUP_DIR/config-$DATE.tar.gz \
    config.conf \
    mediamtx.yml \
    *.sh \
    com.orangead.mock-webcam.plist

# Backup logs (last 7 days)
find logs/ -name "*.log" -mtime -7 -exec cp {} $BACKUP_DIR/ \;

# Cleanup old backups (keep 30 days)
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete

echo "Backup completed: $BACKUP_DIR/config-$DATE.tar.gz"
```

### Service Recovery
```bash
# Complete service recovery
#!/bin/bash
# recover.sh

echo "Stopping all services..."
./stop.sh
pkill -9 -f ffmpeg
pkill -9 -f mediamtx

echo "Cleaning up resources..."
rm -rf /tmp/webcam/*
rm -f mediamtx.log

echo "Restarting services..."
./start-dual.sh

echo "Testing recovery..."
sleep 10
if nc -z localhost 8554; then
    echo "Service recovery successful"
else
    echo "Service recovery failed - manual intervention required"
    exit 1
fi
```

## Maintenance Procedures

### Daily Maintenance
```bash
#!/bin/bash
# daily_maintenance.sh

# Check service status
systemctl is-active orangead-mock-webcam || systemctl restart orangead-mock-webcam

# Clean up old frames
find /tmp/webcam -name "*.webp" -mtime +1 -delete

# Rotate logs
logrotate -f /etc/logrotate.d/orangead-mock-webcam

# Check disk space
df -h /tmp/webcam | awk 'NR==2{if($5+0 > 80) print "WARNING: Disk usage > 80%"}'
```

### Weekly Maintenance
```bash
#!/bin/bash
# weekly_maintenance.sh

# Update MediaMTX if needed
./setup.sh

# Backup configuration
./backup.sh

# Performance monitoring
./monitor.sh > logs/weekly-performance-$(date +%Y%m%d).log

# Security audit
find /opt/orangead-mock-webcam -type f -perm /o+w -ls
```

---

**Last Updated**: October 2025
**Guide Type**: Comprehensive Integration & Deployment
**Target Audience**: System Administrators, DevOps Engineers
**Revision**: 1.0