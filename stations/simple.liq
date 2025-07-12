# Load a playlist from the specified .m3u file
playlist = mksafe(playlist("playlists/playlist1.pls"))

# Apply crossfade with correct parameters to create smooth transitions
# crossfaded_playlist = crossfade(
#  ~start_next=5.0,
#  ~fade_in=3.0,
#  ~fade_out=3.0,
#  playlist
#)

# Output stream to Icecast server
output.icecast(
  %mp3, host="localhost", port=8000, password="changeme",
  mount="/stream",
  playlist
)
