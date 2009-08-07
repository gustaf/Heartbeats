class Playlist < ActiveRecord::Base
  validate :url_is_valid
  belongs_to :user

  def url_is_valid
    is_http_url? || is_spotify_url?
  end

  def is_http_url?
    url =~ Regexp.union(
      /^http:\/\/open\.spotify\.com\/user\/\w+\/playlist\/\w+$/,
      /^http:\/\/open\.spotify\.com\/(album|artist|track)\/\w+$/)
  end

  def is_spotify_url?
    url =~ Regexp.union(
      /^spotify:user:\w+:playlist:\w+$/,
      /^spotify:(album|artist|track):\w+$/)
  end

  class << self
    def find_by_uid(fb_uid)
      all(:joins => :user, :conditions => {:users => {:fb_uid => fb_uid}})
    end
  end
end

#http://open.spotify.com/user/liuia_drusilla/playlist/65xA2Ne13VQzS5spyoXTYo
#spotify:user:liuia_drusilla:playlist:65xA2Ne13VQzS5spyoXTYo
#http://open.spotify.com/user/simonhildor/playlist/2ilB8LwvGQLnBYauSqbS7O
#spotify:user:simonhildor:playlist:2ilB8LwvGQLnBYauSqbS7O
#http://open.spotify.com/user/kallus/playlist/70WmAjFfS3JlfcWrzp6dsw
#spotify:user:kallus:playlist:70WmAjFfS3JlfcWrzp6dsw
#http://open.spotify.com/album/0TMIeuykc2gfMc68YGppoh
#spotify:album:0TMIeuykc2gfMc68YGppoh
#http://open.spotify.com/artist/5cMgGlA1xGyeAB2ctYlRdZ
#spotify:artist:5cMgGlA1xGyeAB2ctYlRdZ
#http://open.spotify.com/track/49kmDZc1NYAFxR3TrLDJLU
#spotify:track:49kmDZc1NYAFxR3TrLDJLU
