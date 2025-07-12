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
│   └── station_with_dirs.liq  # Multi-directory mixing station
├── playlists/
│   └── playlist1.pls          # Playlist file for simple station
├── media/
│   ├── artist1/               # Media files for artist 1
│   └── artist2/               # Media files for artist 2
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

### Running Multiple Stations Simultaneously

Each station is configured with different telnet ports to avoid conflicts:

```bash
# Terminal 1: Simple station
liquidsoap stations/simple.liq &

# Terminal 2: Multi-directory station
liquidsoap stations/station_with_dirs.liq &

# Check both are running
ps aux | grep liquidsoap
```

## Telnet Control

### Connecting to Telnet

```bash
# Connect to simple station
telnet localhost 1234

# Connect to multi-directory station  
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

### Log Files

```bash
# Icecast server logs
docker-compose logs icecast

# Liquidsoap logs (when run with -v flag)
liquidsoap stations/simple.liq -v > station.log 2>&1
```

## Testing Your Setup

1. **Start Icecast**: `docker-compose up -d`
2. **Add media files** to appropriate directories
3. **Start a station**: `liquidsoap stations/simple.liq -t -v`
4. **Open stream in VLC**: `http://localhost:8000/station1`
5. **Test telnet control**: `telnet localhost 1234`

## Advanced Features

- **Crossfade**: Uncomment crossfade sections in station files
- **Multiple formats**: Add different encoding outputs
- **Scheduling**: Add time-based switching
- **Live input**: Add microphone or line-in support
- **Metadata**: Add dynamic metadata and now-playing info

## License

This project is provided as-is for educational and personal use.
