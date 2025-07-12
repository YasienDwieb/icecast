#
# Simple station mixing files from two directories
#

# Configure telnet server on different port
server.telnet(port=1235)

# 1) Create playlist sources from directories:
artist1_source = playlist.list(list.shuffle(file.ls(absolute=true, "media/artist1")))
artist2_source = playlist.list(list.shuffle(file.ls(absolute=true, "media/artist2")))

# 2) Rotate between the two sources (alternating tracks):
mixed = rotate(weights=[1, 1], [artist1_source, artist2_source])

# 3) Fallback to a short silence clip if nothing's found:
silence = single("/usr/share/sounds/alsa/Front_Center.wav")
radio   = fallback(track_sensitive = false, [mixed, silence])

# 4) Normalize volume for consistent loudness:
normalized = normalize(radio, target = -14.0)

# 5) Send to Icecast in MP3 at 128 kbps:
output.icecast(
  %mp3(bitrate = 128),
  host        = "localhost",
  port        = 8000,
  password    = "changeme",
  mount       = "/albums_mix",
  name        = "All in One Mix",
  description = "Mixed albums from two directories",
  normalized
)
