require 'test_helper'

class PlaylistTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "url conversion" do
    p = Playlist.new
    p.url = "http://open.spotify.com/user/kallus/playlist/1d4k8YcfQlYboldYh8sNm1"
    assert p.url_spotify == "spotify:user:kallus:playlist:1d4k8YcfQlYboldYh8sNm1"
    p.url = "http://open.spotify.com/track/5XrnIpFm4PgYft5RNGEDxF"
    assert p.url_spotify == "spotify:track:5XrnIpFm4PgYft5RNGEDxF"
  end
end
