# Icecast Streaming Setup

A complete Icecast streaming setup with Liquidsoap stations for streaming audio content.

## Requirements

### System Requirements
- **Docker & Docker Compose** - For running Icecast server
- **Liquidsoap** - For streaming audio (version 2.2.4+ recommended)
- **Linux/macOS/Windows** - Cross-platform support

### Installation

#### Install Docker & Docker Compose
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install docker.io docker-compose

# macOS (using Homebrew)
brew install docker docker-compose

# Or install Docker Desktop for GUI management
```

#### Install Liquidsoap
```bash
# Ubuntu/Debian
sudo apt install liquidsoap

# macOS (using Homebrew)
brew install liquidsoap

# Or compile from source: https://github.com/savonet/liquidsoap
```

## Project Structure

```
icecast/
├── docker-compose.yml          # Icecast server configuration
├── stations/
│   ├── simple.liq             # Simple playlist-based station
│   ├── station_with_dirs.liq  # Multi-directory mixing station
│   └── simple_hls.liq         # HLS video streaming station
├── playlists/
│   ├── playlist1.pls          # Playlist file for simple station
│   └── playlist-videos.pls    # Video playlist for HLS station
├── media/
│   ├── artist1/               # Media files for artist 1
│   ├── artist2/               # Media files for artist 2
│   └── videos/                # Video files for HLS streaming
├── streams-dir/               # HLS output directory (auto-created)
└── README.md                  # This file
```

## Setup Instructions

### 1. Start Icecast Server

```bash
# Start Icecast server in background
docker-compose up -d

# Check if running
docker-compose ps
```

### 2. How to Check if Icecast is Running

#### Check Server Status
```bash
# Check container status
docker-compose ps

# Check server logs
docker-compose logs icecast

# Check if port 8000 is open
curl -I http://localhost:8000
```

#### Access Icecast Web Interface
- **URL**: http://localhost:8000
- **Admin Interface**: http://localhost:8000/admin
- **Admin Password**: `changeme` (configured in docker-compose.yml)

#### View Connected Stations and Listeners
1. Open http://localhost:8000 in your browser
2. Click "Server Status" to see:
   - Active mount points (stations)
   - Connected listeners
   - Bitrate and format information
   - Stream metadata

### 3. How to Populate Media Folders

#### For Simple Station (playlist-based)
1. Add audio files to any location
2. Update `playlists/playlist1.pls` with file paths:
```
/path/to/your/song1.mp3
/path/to/your/song2.mp3
/home/user/Music/favorite.mp3
```

#### For Multi-Directory Station
1. Create directory structure:
```bash
mkdir -p media/artist1 media/artist2
```

2. Add MP3 files to respective directories:
```bash
# Copy your audio files
cp /path/to/artist1-songs/*.mp3 media/artist1/
cp /path/to/artist2-songs/*.mp3 media/artist2/
```

3. Supported formats: MP3, FLAC, OGG, WAV, etc.

#### For HLS Video Station
1. Create video directory structure:
```bash
mkdir -p media/videos
```

2. Add video files to the directory:
```bash
# Copy your video files
cp /path/to/your/videos/*.mp4 media/videos/
cp /path/to/your/videos/*.avi media/videos/
```

3. Update `playlists/playlist-videos.pls` with file paths:
```
/full/path/to/your/video1.mp4
/full/path/to/your/video2.avi
/home/user/Videos/movie.mkv
```

4. Supported formats: MP4, AVI, MOV, MKV, WMV, etc.
5. **Note**: Use full absolute paths in the playlist file for video files.

## Running Stations

### Simple Station (Playlist-based)

**Features:**
- Plays files from a playlist
- Basic metadata support
- Crossfade (commented out, can be enabled)

**Run Command:**
```bash
# Test mode with verbose output
liquidsoap stations/simple.liq -t -v

# Normal mode (background)
liquidsoap stations/simple.liq

# With custom telnet port (to avoid conflicts)
liquidsoap stations/simple.liq -t -v
```

**Stream Access:**
- **URL**: http://localhost:8000/station1
- **Telnet Control**: Port 1234

### Multi-Directory Station

**Features:**
- Alternates between two directories
- Automatic shuffling
- Volume normalization
- Fallback to silence if no media found

**Run Command:**
```bash
# Test mode with verbose output
liquidsoap stations/station_with_dirs.liq -t -v

# Normal mode (background)
liquidsoap stations/station_with_dirs.liq
```

**Stream Access:**
- **URL**: http://localhost:8000/albums_mix
- **Telnet Control**: Port 1235

### HLS Video Streaming Station

**Features:**
- HTTP Live Streaming (HLS) with adaptive bitrate
- Multiple quality streams (AAC low-fi, FLAC hi-fi, FLAC hi-res)
- Video transcoding with H.264 codec
- Supports video files (MP4, AVI, MOV, etc.)
- Automatic failover and continuous playback
- Client-side quality adaptation based on bandwidth

**Quality Profiles:**
- **AAC Low-Fi**: 192kbps AAC audio, 44.1kHz - Mobile/low bandwidth
- **FLAC Hi-Fi**: Lossless FLAC audio, 44.1kHz - High quality systems
- **FLAC Hi-Res**: Lossless FLAC audio, 48kHz - Professional/studio use

**Setup Instructions:**
1. **Add video files** to your media directory:
```bash
mkdir -p media/videos
cp /path/to/your/videos/*.mp4 media/videos/
```

2. **Update video playlist** (`playlists/playlist-videos.pls`):
```
/path/to/your/video1.mp4
/path/to/your/video2.mp4
/home/user/Videos/movie.mp4
```

3. **Ensure streams directory exists**:
```bash
mkdir -p streams-dir
```

**Run Command:**
```bash
# Test mode with verbose output
liquidsoap stations/simple_hls.liq -t -v

# Normal mode (background)
liquidsoap stations/simple_hls.liq

# Monitor output directory
watch -n 1 "ls -la streams-dir/"
```

**Stream Access:**
- **Master Playlist**: `streams-dir/live.m3u8`
- **AAC Low-Fi Stream**: `streams-dir/aac_lofi/`
- **FLAC Hi-Fi Stream**: `streams-dir/flac_hifi/`
- **FLAC Hi-Res Stream**: `streams-dir/flac_hires/`
- **Telnet Control**: Port 1235

**Client Usage:**
```bash
# VLC Media Player
vlc streams-dir/live.m3u8

# FFplay
ffplay streams-dir/live.m3u8

# Web browsers (with HLS support)
# Serve the streams-dir via HTTP server:
python3 -m http.server 8080
# Then access: http://localhost:8080/live.m3u8
```

**Nginx Integration:**
For production deployments, use nginx to serve HLS content:

1. **Install nginx:**
```bash
sudo apt install nginx
```

2. **Create nginx configuration** (`/etc/nginx/sites-available/hls-streaming`):
```nginx
server {
    listen 80;
    server_name localhost;
    
    # HLS streaming location
    location /hls/ {
        root /path/to/your/icecast/;
        alias /path/to/your/icecast/streams-dir/;
        
        # HLS specific headers
        add_header Cache-Control no-cache;
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods GET;
        
        # CORS headers for web players
        add_header Access-Control-Allow-Headers Range;
        
        # HLS file types
        location ~* \.(m3u8)$ {
            expires -1;
            add_header Cache-Control no-cache;
        }
        
        location ~* \.(ts)$ {
            expires 1h;
            add_header Cache-Control public;
        }
    }
    
    # Optional: Serve a simple web player
    location / {
        root /var/www/html;
        index index.html;
    }
}
```

3. **Enable the site:**
```bash
sudo ln -s /etc/nginx/sites-available/hls-streaming /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

4. **Access HLS streams:**
```bash
# Master playlist
http://localhost/hls/live.m3u8

# Direct quality streams
http://localhost/hls/aac_lofi/
http://localhost/hls/flac_hifi/
http://localhost/hls/flac_hires/
```

5. **Simple HTML player example** (`/var/www/html/index.html`):
```html
<!DOCTYPE html>
<html>
<head>
    <title>HLS Stream Player</title>
    <script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
</head>
<body>
    <video id="video" controls width="800" height="600"></video>
    <script>
        const video = document.getElementById('video');
        const videoSrc = '/hls/live.m3u8';
        
        if (Hls.isSupported()) {
            const hls = new Hls();
            hls.loadSource(videoSrc);
            hls.attachMedia(video);
        } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
            video.src = videoSrc;
        }
    </script>
</body>
</html>
```

**Requirements:**
- **FFmpeg**: Required for video transcoding
- **Storage**: HLS generates many small files, ensure adequate disk space
- **CPU**: Video transcoding is CPU-intensive, especially for multiple streams

### Running Multiple Stations Simultaneously

Each station is configured with different telnet ports to avoid conflicts:

```bash
# Terminal 1: Simple station
liquidsoap stations/simple.liq &

# Terminal 2: Multi-directory station
liquidsoap stations/station_with_dirs.liq &

# Terminal 3: HLS video station
liquidsoap stations/simple_hls.liq &

# Check all are running
ps aux | grep liquidsoap
```

**Note for HLS Station**: The HLS station outputs to files rather than Icecast, so it doesn't conflict with Icecast mount points. However, it still uses telnet port 1235, so it conflicts with the multi-directory station. Run only one at a time, or modify the telnet port in one of the configurations.

## Telnet Control

### Connecting to Telnet

```bash
# Connect to simple station
telnet localhost 1234

# Connect to multi-directory station  
telnet localhost 1235

# Connect to HLS video station
telnet localhost 1235
```

### Sample Telnet Commands

Once connected to telnet, you can use these commands:

#### Basic Information
```bash
# Show help
help

# Show current song
request.metadata

# Show queue
request.queue

# Show all available commands
list
```

#### Playback Control
```bash
# Skip to next track
skip

# Show current source
source.info

# Get current position in track
source.time

# Check if source is ready
source.is_ready
```

#### Queue Management
```bash
# Add a track to queue (for simple station)
request.push /path/to/song.mp3

# Remove track from queue
request.remove <id>

# Clear queue
request.clear
```

#### Volume Control
```bash
# Set volume (0.0 to 1.0)
amplify.set 0.8

# Get current volume
amplify.get
```

#### Server Information
```bash
# Show server uptime
uptime

# Show server version
version

# Show liquidsoap configuration
liquidsoap.version
```

#### Exit Telnet
```bash
# Exit telnet session
exit
# or press Ctrl+] then type quit
```

## Configuration

### Icecast Server Settings

Edit `docker-compose.yml` to modify:
- **Port**: Change `8000:8000` to use different port
- **Passwords**: Update all password environment variables
- **Hostname**: Change `ICECAST_HOSTNAME` for public streaming

### Station Settings

Both station files can be customized:

#### Simple Station (`stations/simple.liq`)
- **Mount point**: `/station1`
- **Telnet port**: 1234
- **Playlist**: `playlists/playlist1.pls`

#### Multi-Directory Station (`stations/station_with_dirs.liq`)
- **Mount point**: `/albums_mix`
- **Telnet port**: 1235
- **Directories**: `media/artist1`, `media/artist2`

#### HLS Video Station (`stations/simple_hls.liq`)
- **Output directory**: `streams-dir/`
- **Master playlist**: `live.m3u8`
- **Telnet port**: 1235
- **Video playlist**: `playlists/playlist-videos.pls`
- **Quality profiles**: AAC low-fi, FLAC hi-fi, FLAC hi-res

## Troubleshooting

### Common Issues

1. **"Address already in use"**
   - Another Liquidsoap instance is running
   - Kill existing processes: `pkill liquidsoap`

2. **"Connection refused"**
   - Icecast server not running
   - Check: `docker-compose ps`

3. **No audio files found**
   - Check file paths in playlists
   - Ensure media directories contain audio files

4. **Telnet connection fails**
   - Check if telnet port is configured correctly
   - Verify Liquidsoap is running

5. **HLS Station Issues**
   - **FFmpeg not found**: Install FFmpeg (`sudo apt install ffmpeg`)
   - **Video files not playing**: Check file paths in `playlists/playlist-videos.pls`
   - **No HLS output**: Check if `streams-dir/` exists and is writable
   - **High CPU usage**: Video transcoding is resource-intensive, consider reducing quality profiles
   - **Disk space filling up**: HLS creates many small files, monitor disk usage

### Log Files

```bash
# Icecast server logs
docker-compose logs icecast

# Liquidsoap logs (when run with -v flag)
liquidsoap stations/simple.liq -v > station.log 2>&1
```

## Testing Your Setup

### For Audio Streaming (Icecast)
1. **Start Icecast**: `docker-compose up -d`
2. **Add media files** to appropriate directories
3. **Start a station**: `liquidsoap stations/simple.liq -t -v`
4. **Open stream in VLC**: `http://localhost:8000/station1`
5. **Test telnet control**: `telnet localhost 1234`

### For HLS Video Streaming
1. **Ensure FFmpeg is installed**: `ffmpeg -version`
2. **Add video files** to `media/videos/` directory
3. **Update video playlist**: Edit `playlists/playlist-videos.pls`
4. **Start HLS station**: `liquidsoap stations/simple_hls.liq -t -v`
5. **Check output**: `ls -la streams-dir/`
6. **Test playback**: `vlc streams-dir/live.m3u8`
7. **Test telnet control**: `telnet localhost 1235`

## Advanced Features

- **Crossfade**: Uncomment crossfade sections in station files
- **Multiple formats**: Add different encoding outputs
- **Scheduling**: Add time-based switching
- **Live input**: Add microphone or line-in support
- **Metadata**: Add dynamic metadata and now-playing info

## License

This project is provided as-is for educational and personal use.
