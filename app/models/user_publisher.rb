class UserPublisher < Facebooker::Rails::Publisher
  def playlist_added_template
    one_line_story_template "{*actor*} shared a Spotify playlist on SpotifyConnect."
    stories = ["{*actor*} shared a Spotify playlist on SpotifyConnect.","Share your playlist on SpotifyConnect <a href='http://localhost:9930/'>here</a>! {*target*} shared their playlists on <a href='http://localhost:9930/'>SpotifyConnect</a>."]
    short_story_template *stories
    full_story_template *stories
  end
  
  def playlist_added(facebook_user)
    send_as :user_action
    from facebook_user
  end
end
