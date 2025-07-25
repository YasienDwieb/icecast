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
/path/to/your/file1.mp3
/path/to/your/file2.mp3
/home/user/Media/favorite.mp3
```

#### For Multi-Directory Station
1. Create directory structure:
```bash
mkdir -p media/artist1 media/artist2
```

2. Add MP3 files to respective directories:
```bash
# Copy your audio files
cp /path/to/artist1-files/*.mp3 media/artist1/
cp /path/to/artist2-files/*.mp3 media/artist2/
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
For production HLS serving, create `/etc/nginx/sites-available/hls-streaming`:

```nginx
server {
    listen 80;
    location /hls/ {
        alias /path/to/your/icecast/streams-dir/;
        add_header Cache-Control no-cache;
        add_header Access-Control-Allow-Origin *;
    }
}
```

Enable and reload:
```bash
sudo ln -s /etc/nginx/sites-available/hls-streaming /etc/nginx/sites-enabled/
sudo systemctl reload nginx
```

Access: `http://localhost/hls/live.m3u8`

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

# Show current track
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
request.push /path/to/file.mp3

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

## Adding a New Station

### Step-by-Step Guide

To add a new station to your icecast setup, follow these steps:

#### 1. **Create Station Configuration File**
Create a new `.liq` file in the `stations/` directory:

```bash
# Example: Create a new station
touch stations/new_station.liq
```

#### 2. **Choose Station Type and Template**
Use existing stations as templates:

- **For playlist-based stations**: Use `stations/simple.liq` as template
- **For directory-based stations**: Use `stations/station_with_dirs.liq` as template  
- **For HLS video streaming**: Use `stations/simple_hls.liq` as template

#### 3. **Configure Station Settings**
Edit your new station file with these key settings:

```liquidsoap
# REQUIRED: Unique telnet port (avoid conflicts)
server.telnet(port=1236)  # Change port number

# For Icecast stations:
output.icecast(
  %mp3(bitrate = 128),
  host = "localhost",
  port = 8000,
  password = "changeme",
  mount = "/new_station",    # REQUIRED: Unique mount point
  name = "New Station",      # Station name
  description = "24/7 Media Stream",
  genre = "Various",
  # ... your audio source
)

# For HLS stations:
output.file.hls(
  playlist = "new_live.m3u8",     # REQUIRED: Unique playlist name
  "new-streams-dir/",             # REQUIRED: Unique output directory
  streams,
  radio
)
```

#### 4. **Create Media Sources**
Choose one of these approaches:

**Option A: Playlist-based**
```bash
# Create playlist file
touch playlists/new_playlist.pls

# Add file paths to playlist
echo "/path/to/media/file1.mp3" >> playlists/new_playlist.pls
echo "/path/to/media/file2.mp3" >> playlists/new_playlist.pls
```

**Option B: Directory-based**
```bash
# Create media directories
mkdir -p media/artist/album1
mkdir -p media/artist/album2

# Copy media files
cp /path/to/media/*.mp3 media/artist/album1/
```

**Option C: HLS Video**
```bash
# Create video directory and playlist
mkdir -p media/artist_videos
touch playlists/artist_videos.pls

# Add video file paths
echo "/path/to/video1.mp4" >> playlists/artist_videos.pls
```

#### 5. **Update Station Configuration**
Edit your station file to use the media sources:

```liquidsoap
# For playlist-based
radio = mksafe(playlist("playlists/new_playlist.pls"))

# For directory-based
album1 = playlist.list(list.shuffle(file.ls(absolute=true, "media/artist/album1")))
album2 = playlist.list(list.shuffle(file.ls(absolute=true, "media/artist/album2")))
radio = rotate(weights=[1, 1], [album1, album2])

# For HLS video
radio = mksafe(playlist("playlists/artist_videos.pls"))
```

#### 6. **Required Unique Settings Checklist**
Ensure these are unique for each station:

- ✅ **Telnet port**: `server.telnet(port=XXXX)` 
- ✅ **Mount point**: `mount="/unique_name"` (for Icecast)
- ✅ **Playlist name**: `playlist="unique.m3u8"` (for HLS)
- ✅ **Output directory**: `"unique-dir/"` (for HLS)
- ✅ **Media sources**: Separate playlists or directories

#### 7. **Test Your New Station**

```bash
# Test the configuration
liquidsoap stations/new_station.liq -t -v

# Run in background
liquidsoap stations/new_station.liq &

# Check if running
ps aux | grep liquidsoap
```

#### 8. **Access Your New Station**

**For Icecast stations:**
```bash
# Stream URL
http://localhost:8000/new_station

# Telnet control
telnet localhost 1236
```

**For HLS stations:**
```bash
# Check output
ls -la new-streams-dir/

# Play with VLC
vlc new-streams-dir/new_live.m3u8
```

### Port Management

Keep track of used ports to avoid conflicts:

| Station | Telnet Port | Mount Point | Status |
|---------|-------------|-------------|--------|
| Simple | 1234 | /station1 | ✅ Used |
| Multi-dir | 1235 | /albums_mix | ✅ Used |
| HLS Video | 1235 | N/A (file output) | ✅ Used |
| New Station (example) | 1236 | /new_station | 🆕 Available |

### File Structure After Adding Station

```
icecast/
├── stations/
│   ├── simple.liq
│   ├── station_with_dirs.liq
│   ├── simple_hls.liq
│   └── new_station.liq          # ← New station
├── playlists/
│   ├── playlist1.pls
│   ├── playlist-videos.pls
│   └── new_playlist.pls         # ← New playlist
├── media/
│   ├── artist1/
│   ├── artist2/
│   ├── videos/
│   └── artist/                  # ← New media directory
│       ├── album1/
│       └── album2/
├── streams-dir/                 # HLS output
├── new-streams-dir/             # ← New HLS output (if applicable)
└── README.md
```

### Common Issues When Adding Stations

1. **Port conflicts**: Use unique telnet ports
2. **Mount point conflicts**: Use unique mount points for Icecast
3. **File permissions**: Ensure liquidsoap can read media files
4. **Path issues**: Use absolute paths in playlists
5. **Directory creation**: Create output directories for HLS stations

## Advanced Features

- **Crossfade**: Uncomment crossfade sections in station files
- **Multiple formats**: Add different encoding outputs
- **Scheduling**: Add time-based switching
- **Live input**: Add microphone or line-in support
- **Metadata**: Add dynamic metadata and now-playing info

## License

This project is provided as-is for educational and personal use.
