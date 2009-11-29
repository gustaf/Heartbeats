class PlaylistsController < ApplicationController
  before_filter :set_facebook_session, :ensure_logged_in_and_get_user
  
  def index
    render :text => "playlists/index"
  end
  
  def show
    render :text => "playlists/show"
  end
  
  def create
    playlist = Playlist.create(:user => @user, :url => params[:playlist][:url])

    if playlist
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
