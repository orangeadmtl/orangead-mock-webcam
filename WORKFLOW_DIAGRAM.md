# OrangeAd Mock Webcam - Workflow Diagrams

## System Architecture Overview

```mermaid
%%{init: {
  'theme': 'base',
  'themeVariables': {
    'primaryColor': '#1f2937',
    'primaryTextColor': '#f8fafc',
    'primaryBorderColor': '#374151',
    'lineColor': '#6b7280',
    'sectionBkgColor': '#1e293b',
    'altSectionBkgColor': '#18181b',
    'gridColor': '#374151',
    'secondaryColor': '#3b82f6',
    'tertiaryColor': '#10b981',
    'background': '#111827',
    'textColor': '#f1f5f9',
    'edgeLabelBackground': '#374151',
    'clusterBkg': '#374151',
    'clusterBorder': '#6b7280',
    'titleColor': '#f8fafc'
  }
}}%%
graph TB
    subgraph InputSources [Input Sources]
        A1[Video Files<br/>sample.mp4]
        A2[Camera Devices<br/>/dev/video0]
        A3[Network Streams<br/>RTSP/HTTP]
    end

    subgraph ProcessingLayer [Processing Layer]
        B1[FFmpeg Pipeline<br/>Transcoding Engine]
        B2[Stream Splitter<br/>Dual-Output Architecture]
        B3[Format Conversion<br/>H.264 + WebP]
    end

    subgraph OutputLayer [Output Layer]
        C1[MediaMTX Server<br/>Multi-Protocol Streaming]
        C2[Local Frame Storage<br/>/tmp/webcam/]
        C3[RTSP Stream<br/>Port 8554]
    end

    subgraph ConsumerApplications [Consumer Applications]
        D1[oaTracker<br/>Human Detection]
        D2[oaParkingMonitor<br/>Vehicle Detection]
        D3[Video Players<br/>VLC/mpv/ffplay]
        D4[Web Browsers<br/>WebRTC/HLS]
    end

    A1 --> B1
    A2 --> B1
    A3 --> B1
    B1 --> B2
    B2 --> B3
    B3 --> C1
    B3 --> C2
    C1 --> C3
    C3 --> D1
    C3 --> D2
    C3 --> D3
    C3 --> D4
    C2 --> D1
    C2 --> D2

    classDef input fill:#3b82f6,stroke:#1e3a8a,color:#f8fafc
    classDef processing fill:#8b5cf6,stroke:#6d28d9,color:#f8fafc
    classDef output fill:#10b981,stroke:#065f46,color:#f8fafc
    classDef consumer fill:#f59e0b,stroke:#d97706,color:#f8fafc

    class A1,A2,A3 input
    class B1,B2,B3 processing
    class C1,C2,C3 output
    class D1,D2,D3,D4 consumer
```

## Dual-Output Architecture Flow

```mermaid
sequenceDiagram
    participant S as Input Source
    participant F as FFmpeg
    participant SP as Stream Splitter
    participant M as MediaMTX
    participant FS as File System
    participant C as Consumer Apps

    S->>F: Video Input (File/Camera)
    F->>F: Decode & Process
    F->>SP: Split Video Stream
    par Dual Output Generation
        SP->>M: H.264 RTSP Feed
        M->>C: RTSP Stream :8554
    and
        SP->>FS: WebP Frame Sequence
        FS->>C: Local Frames /tmp/webcam/
    end

    Note over F,FS: Low Latency: <100ms for frames
    Note over M,C: Standard Latency: 200-500ms for RTSP
```

## Service Lifecycle Management

```mermaid
stateDiagram-v2
    [*] --> Setup: ./setup.sh
    Setup --> ConfigValidation: Check Dependencies
    ConfigValidation --> MediaMTXStart: ./start-dual.sh
    ConfigValidation --> Error: Dependencies Missing

    MediaMTXStart --> MediaMTXReady: Wait for Port 8554
    MediaMTXReady --> FFmpegStart: Port Available
    MediaMTXReady --> Error: Timeout (30s)

    FFmpegStart --> DualOutputRunning: Stream Active
    DualOutputRunning --> Running: Both Outputs Active

    Running --> Cleanup: Ctrl+C / ./stop.sh
    Running --> Error: Process Failure
    Error --> Cleanup: Error Recovery

    Cleanup --> [*]: Services Stopped

    note right of MediaMTXStart
        Background Process
        PID: $MEDIAMTX_PID
        Config: mediamtx.yml
    end note

    note right of FFmpegStart
        Dual Pipeline:
        - RTSP: libx264 ultrafast
        - Frames: libwebp @ 5fps
    end note

    classDef start fill:#10b981,stroke:#065f46,color:#f8fafc
    classDef process fill:#3b82f6,stroke:#1e3a8a,color:#f8fafc
    classDef error fill:#ef4444,stroke:#b91c1c,color:#f8fafc
    classDef end fill:#6b7280,stroke:#374151,color:#f8fafc

    class Setup,MediaMTXStart,FFmpegStart start
    class ConfigValidation,MediaMTXReady,DualOutputRunning,Running process
    class Error error
    class Cleanup end
```

## Multi-Protocol Streaming Architecture

```mermaid
graph LR
    subgraph MediaMTXCore [MediaMTX Core]
        A[RTSP Server<br/>:8554]
        B[RTMP Server<br/>:1935]
        C[HLS Server<br/>:8888]
        D[WebRTC Server<br/>:8889]
        E[SRT Server<br/>:8890]
    end

    subgraph InputSources2 [Input Sources]
        F[FFmpeg Pipeline<br/>H.264 Stream]
    end

    subgraph ClientApplications [Client Applications]
        G[oaTracker<br/>RTSP Client]
        H[Video Players<br/>RTSP/RTMP/HLS]
        I[Web Browsers<br/>HLS/WebRTC]
        J[Broadcast Tools<br/>RTMP/SRT]
        K[Mobile Apps<br/>HLS/WebRTC]
    end

    F --> A
    F --> B
    F --> C
    F --> D
    F --> E

    A --> G
    A --> H
    B --> H
    B --> J
    C --> I
    C --> K
    D --> I
    E --> J

    classDef core fill:#1f2937,stroke:#111827,color:#f8fafc
    classDef input fill:#3b82f6,stroke:#1e3a8a,color:#f8fafc
    classDef client fill:#10b981,stroke:#065f46,color:#f8fafc

    class A,B,C,D,E core
    class F input
    class G,H,I,J,K client
```

## Configuration Management Flow

```mermaid
flowchart TD
    A[Service Start] --> B[Load config.conf]
    B --> C{Config File Exists?}
    C -->|Yes| D[Parse Configuration]
    C -->|No| E[Use Environment Variables]

    D --> F[Validate Parameters]
    E --> F
    F --> G{All Parameters Valid?}

    G -->|Yes| H[Apply Configuration]
    G -->|No| I[Use Default Values]

    H --> J[Start MediaMTX]
    I --> J

    J --> K[Start FFmpeg Pipeline]
    K --> L{Services Ready?}

    L -->|Yes| M[RUNNING STATE]
    L -->|No| N[Error Handling]

    N --> O[Cleanup & Exit]
    M --> P[Monitor Services]
    P --> Q{Health Check OK?}

    Q -->|Yes| P
    Q -->|No| R[Restart Services]
    R --> J

    style A fill:#3b82f6,color:#f8fafc
    style M fill:#10b981,color:#f8fafc
    style N,O fill:#ef4444,color:#f8fafc
    style P,Q,R fill:#f59e0b,color:#f8fafc
```

## Resource Management Flow

```mermaid
sequenceDiagram
    participant S as System
    participant C as Cleanup Process
    participant FS as File System
    participant F as FFmpeg
    participant M as MediaMTX

    Note over S,M: Service Startup
    S->>FS: Create /tmp/webcam/
    S->>C: Start cleanup process (PID: $CLEANUP_PID)
    S->>M: Start MediaMTX
    S->>F: Start FFmpeg dual pipeline

    loop Frame Generation
        F->>FS: Write WebP frames
        Note over FS: Frame rate: 5fps
    end

    loop Background Cleanup
        C->>FS: Check file count
        alt File count > MAX_FILES
            FS->>C: Return file list
            C->>FS: Delete oldest files
            Note over C: Keep latest 10,000 files
        end
        Note over C: Interval: 1 second
    end

    Note over S,M: Service Shutdown
    S->>C: Kill cleanup process
    S->>F: Kill FFmpeg process
    S->>M: Kill MediaMTX process
    S->>FS: Cleanup frame directory
```

## Error Handling and Recovery Flow

```mermaid
graph TD
    A[Normal Operation] --> B{Error Detected?}
    B -->|No| A
    B -->|Yes| C[Identify Error Type]

    C --> D{MediaMTX Error?}
    C --> E{FFmpeg Error?}
    C --> F{Resource Error?}
    C --> G{Network Error?}

    D -->|Yes| H[Restart MediaMTX]
    E -->|Yes| I[Restart FFmpeg]
    F -->|Yes| J[Free Resources]
    G -->|Yes| K[Check Network]

    H --> L{Recovery Successful?}
    I --> L
    J --> L
    K --> L

    L -->|Yes| M[Resume Operation]
    L -->|No| N[Escalate Error]

    M --> A
    N --> O[Graceful Shutdown]
    O --> P[Log Error Details]
    P --> Q[Service Stopped]

    classDef normal fill:#10b981,color:#f8fafc
    classDef check fill:#3b82f6,color:#f8fafc
    classDef error fill:#ef4444,color:#f8fafc
    classDef recovery fill:#f59e0b,color:#f8fafc
    classDef stop fill:#6b7280,color:#f8fafc

    class A,M normal
    class B,D,E,F,G,L check
    class C,N error
    class H,I,J,K recovery
    class O,P,Q stop
```

## Integration with OrangeAd Ecosystem

```mermaid
graph TB
    subgraph OrangeAdMockWebcam [OrangeAd Mock Webcam]
        A1[FFmpeg Pipeline]
        A2[MediaMTX Server]
        A3[Frame Storage]
    end

    subgraph DetectionServices [Detection Services]
        B1[oaTracker<br/>Port 8080]
        B2[oaParkingMonitor<br/>Port 8091]
    end

    subgraph ManagementLayer [Management Layer]
        C1[oaDashboard<br/>Web Interface]
        C2[oaAnsible<br/>Deployment]
    end

    subgraph DeviceLayer [Device Layer]
        D1[macOS Device]
        D2[Ubuntu Device]
        D3[OrangePi 5B]
    end

    subgraph NetworkInfrastructure [Network Infrastructure]
        E1[Tailscale VPN]
        E2[Local Network]
    end

    A1 --> A2
    A1 --> A3
    A2 --> B1
    A2 --> B2
    A3 --> B1
    A3 --> B2

    C1 --> B1
    C1 --> B2
    C1 --> A1
    C2 --> A1

    B1 --> D1
    B2 --> D2
    B2 --> D3

    E1 --> B1
    E1 --> B2
    E1 --> C1
    E2 --> D1
    E2 --> D2
    E2 --> D3

    classDef mockWebcam fill:#8b5cf6,color:#f8fafc
    classDef detection fill:#10b981,color:#f8fafc
    classDef management fill:#f59e0b,color:#f8fafc
    classDef device fill:#3b82f6,color:#f8fafc
    classDef network fill:#6b7280,color:#f8fafc

    class A1,A2,A3 mockWebcam
    class B1,B2 detection
    class C1,C2 management
    class D1,D2,D3 device
    class E1,E2 network
```

## Performance Optimization Workflow

```mermaid
flowchart LR
    A[Current Performance] --> B{CPU Usage > 40%?}
    B -->|Yes| C[Reduce Resolution]
    B -->|No| D{Memory Usage > 200MB?}

    C --> E[Adjust Video Size<br/>1280x720 → 640x480]
    E --> F[Lower Frame Rate<br/>10fps → 5fps]

    D -->|Yes| G[Reduce Buffer Size]
    D -->|No| H{Network Latency > 500ms?}

    G --> I[Decrease Queue Size<br/>512 → 256]
    H -->|Yes| J[Enable UDP Transport]
    H -->|No| K{Disk I/O High?}

    J --> L[Optimize Network Settings]
    K -->|Yes| M[Increase Cleanup Interval]
    K -->|No| N[Performance Optimized]

    F --> O[Apply Changes]
    I --> O
    L --> O
    M --> O
    O --> P[Restart Services]
    P --> N

    style A fill:#3b82f6,color:#f8fafc
    style N fill:#10b981,color:#f8fafc
    style P fill:#f59e0b,color:#f8fafc
    style B,D,H,K fill:#8b5cf6,color:#f8fafc
```

## Debugging and Troubleshooting Flow

```mermaid
graph TD
    A[Service Issue] --> B[Check Service Status]
    B --> C{MediaMTX Running?}
    C -->|No| D[Start MediaMTX]
    C -->|Yes| E{FFmpeg Running?}

    D --> F{Start Success?}
    F -->|No| G[Check Port 8554]
    F -->|Yes| H[MediaMTX OK]

    E -->|No| I[Start FFmpeg]
    E -->|Yes| J{Stream Working?}

    I --> K{Start Success?}
    K -->|No| L[Check Input Source]
    K -->|Yes| M[FFmpeg OK]

    J -->|No| N[Check Stream Configuration]
    J -->|Yes| O{Frames Generating?}

    N --> P[Validate RTSP URL]
    O -->|No| Q[Check Frame Directory]
    O -->|Yes| R[Service Fully Operational]

    G --> S{Port Available?}
    S -->|No| T[Kill Conflicting Process]
    S -->|Yes| U[Check MediaMTX Config]

    L --> V{Input Valid?}
    V -->|No| W[Update Input Source]
    V -->|Yes| X[Check FFmpeg Installation]

    Q --> Y{Directory Permissions?}
    Y -->|No| Z[Fix Permissions]
    Y -->|Yes| AA[Check Disk Space]

    T --> D
    U --> D
    W --> I
    X --> I
    Z --> AB[Restart Frame Generation]
    AA --> AB
    AB --> O

    style A fill:#ef4444,color:#f8fafc
    style R fill:#10b981,color:#f8fafc
    style H,M,N,O,P,Q check fill:#3b82f6,color:#f8fafc
    style G,K,S,V,Y decision fill:#8b5cf6,color:#f8fafc
    style D,I,F,J,L,W,X,T,U,Z,AA action fill:#f59e0b,color:#f8fafc
    style AB process fill:#6b7280,color:#f8fafc
```

## Deployment Scenarios

### Single Device Deployment
```mermaid
graph TB
    subgraph DeviceSingleMachine [Device - Single Machine]
        A[orangead-mock-webcam<br/>Port 8554]
        B[oaTracker<br/>Port 8080]
        C[oaParkingMonitor<br/>Port 8091]
        D[oaDashboard<br/>Port 3000]
    end

    subgraph LocalResources [Local Resources]
        E[Video Files<br/>sample.mp4]
        F[Camera Device<br/>/dev/video0]
        G[Frame Storage<br/>/tmp/webcam/]
    end

    E --> A
    F --> A
    A --> B
    A --> C
    B --> D
    C --> D
    A --> G
    G --> B
    G --> C

    classDef service fill:#3b82f6,color:#f8fafc
    classDef resource fill:#10b981,color:#f8fafc

    class A,B,C,D service
    class E,F,G resource
```

### Multi-Device Network Deployment
```mermaid
graph TB
    subgraph DeviceAPrimary [Device A - Primary]
        A1[orangead-mock-webcam<br/>:8554]
        A2[oaTracker<br/>:8080]
    end

    subgraph DeviceBSecondary [Device B - Secondary]
        B1[oaParkingMonitor<br/>:8091]
        B2[oaDashboard<br/>:3000]
    end

    subgraph DeviceCMonitoring [Device C - Monitoring]
        C1[Mobile Client]
        C2[Web Browser]
    end

    subgraph NetworkInfrastructure2 [Network Infrastructure]
        D1[Tailscale VPN]
        D2[Local Router]
    end

    A1 --> D1
    D1 --> B1
    D1 --> B2
    D2 --> C1
    D2 --> C2
    B2 --> D2

    A1 --> A2
    B1 --> B2

    classDef deviceA fill:#3b82f6,color:#f8fafc
    classDef deviceB fill:#10b981,color:#f8fafc
    classDef deviceC fill:#f59e0b,color:#f8fafc
    classDef network fill:#6b7280,color:#f8fafc

    class A1,A2 deviceA
    class B1,B2 deviceB
    class C1,C2 deviceC
    class D1,D2 network
```

---

**Diagram Standards Used:**
- **High Contrast Colors**: Dark backgrounds (#1f2937, #1e293b) with light text (#f8fafc)
- **Consistent Color Coding**: Blue for input, purple for processing, green for output
- **Clear Flow Direction**: Left-to-right and top-to-bottom flow patterns
- **Comprehensive Coverage**: All major system workflows represented
- **Integration Focus**: OrangeAd ecosystem connections clearly shown

**Last Updated**: October 2025
**Diagrams Created**: 12 comprehensive workflow diagrams
**Styling**: High-contrast accessibility compliant