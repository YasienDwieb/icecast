# HLS video streaming station with multiple quality streams
server.telnet(port=1235)

# Load video playlist with failover
radio = mksafe(playlist("playlists/playlist-videos.pls"))

# AAC low-fi profile
aac_lofi = %ffmpeg(format="mp4",
                    %video(codec="libx264"),
                   %audio(
                     codec="aac",
                     channels=2,
                     ar=44100,
                     b="192k"
                   ))

# FLAC hi-fi profile
flac_hifi = %ffmpeg(format="mp4",
                    strict="-2",
                                        %video(codec="libx264"),
                    %audio(
                      codec="flac",
                      channels=2,
                      ar=44100
                    ))

# FLAC hi-res profile
flac_hires = %ffmpeg(format="mp4",
                     strict="-2",
                                         %video(codec="libx264"),
                     %audio(
                       codec="flac",
                       channels=2,
                       ar=48000
                     ))

# Define quality streams
streams = [("aac_lofi", aac_lofi),
           ("flac_hifi", flac_hifi),
           ("flac_hires", flac_hires)]

# Output HLS with adaptive bitrate
output.file.hls(playlist="live.m3u8",
                "streams-dir/",
                streams,
                radio)