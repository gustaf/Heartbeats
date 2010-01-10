require 'net/http'

class PlaylistsController < ApplicationController
  before_filter :set_facebook_session, :ensure_logged_in_and_get_user
  helper_method :facebook_session
  
  def index
    render :text => "playlists/index"
  end
  
  def show
    @playlist = Playlist.find params[:id]
    @creator = @playlist.user
    @liked_by = User.find(:all, :joins => :likes, :conditions => ["likes.playlist_id = ?", @playlist])
    @current_user_like = @user.like_for @playlist
  end
  
  def create
    raw_input = params[:playlist][:url].strip
    # Test to see if it is a plain url or a link with a url and title
    playlist = Playlist.new(:user => @user, :url => raw_input)
    if playlist.is_spotify_url? || playlist.is_http_url?
      playlist.save
    elsif raw_input.match(/<a href.*<\/a>/)
      ## assuming spotify_href in format: "<a href=\"http://open.spotify.com/user/mbrattberg/playlist/3JTNZE3gD7H7eHQ4rOYAEY\">Marie</a>"
      title = raw_input.slice(/>.*<\/a>/)[1...-4]
      url = raw_input[9...(-6 - title.length)]
      playlist = Playlist.new(:user => @user, :url => url, :title => title)
      playlist.save if playlist.is_spotify_url? || playlist.is_http_url?
    else
      playlist = nil
    end
    
    if playlist
      Net::HTTP.get "97.107.141.222", "/playlist/#{playlist.url_spotify}" if playlist.is_proper_playlist?
      playlist.data_requested_at = DateTime.now
      playlist.save
      flash[:playlist_added] = "Show stream publisher"
    end
    
    redirect_to root_url
  end
  
  def destroy 
    id = params[:id]
    playlist = Playlist.find(id)
    if playlist.user == @user
      playlist.destroy 
    end 
    
    redirect_to root_url  
  end

end
