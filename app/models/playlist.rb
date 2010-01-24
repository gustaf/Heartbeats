require 'meta-spotify'
require 'net/http'

class Playlist < ActiveRecord::Base
  validate :url_is_valid
  before_validation :set_url_spotify
  belongs_to :user
  has_many :likes
  has_and_belongs_to_many :tracks
  
  def to_s
    title.blank? ? url : title
  end
  
  # CHECK AND VALIDATE SPOTIFY URL
  def url_is_valid
    errors.add(:url, "url is not valid") unless is_http_url? || is_spotify_url?
  end

  def is_http_url?
    url =~ Regexp.union(
      /^http:\/\/open\.spotify\.com\/user\/[\w\.]+\/playlist\/\w+$/,
      /^http:\/\/open\.spotify\.com\/(album|artist|track)\/\w+$/)
  end
 
  def is_spotify_url?
    url =~ Regexp.union(
      /^spotify:user:[\w\.]+:playlist:\w+$/,
      /^spotify:(album|artist|track):\w+$/)
  end

  def is_proper_playlist?
    url_spotify =~ /^spotify:user:[\w\.]+:playlist:\w+$/
  end

# Get Artist & Trackname through MetaSpotify API Begin
  
  def track_name
    begin
      track = MetaSpotify::Track.lookup(url_spotify)
      return track.name
    rescue Exception => e
      return "Not a Track"
    end
  end  

  def artist_name
    begin
      artist = MetaSpotify::Artist.lookup(url_spotify)
      return artists.name
    rescue Exception => e
      return "Not an Artist"
    end
  end

# Get Artist & Trackname through MetaSpotify API End

  def touch
    playlist = self.class.first(
      :readonly => false,
      :conditions => {:user_id => user.id, :url_spotify => self.class.url_to_url_spotify(url)})
    return unless playlist
    playlist.updated_at = DateTime.now
    playlist.save
  end

  def lookup!
    if is_proper_playlist? then
      Net::HTTP.get "97.107.141.222", "/playlist/#{url_spotify}"
      data_requested_at = DateTime.now
      save
    end
  end

  def artists
    tracks.map{|t| t.artists.map{|a| a.name}}.flatten.uniq
  end

  class << self
    def find_by_uid(uid)
      all(:joins => :user, :conditions => {:users => {:uid => uid}})
    end

    def url_to_url_spotify(url)
      case url
        when /^http:\/\/open\.spotify\.com\/user\/(\w+)\/playlist\/(\w+)$/
          "spotify:user:#{$1}:playlist:#{$2}"
        when /^http:\/\/open\.spotify\.com\/(album|artist|track)\/(\w+)$/
          "spotify:#{$1}:#{$2}"
        else
          url
      end
    end
  end

  protected
  def set_url_spotify
    self.url_spotify ||= self.class.url_to_url_spotify(url)
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
