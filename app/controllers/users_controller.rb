class UsersController < ApplicationController
  before_filter :set_facebook_session, :ensure_logged_in_and_get_user
  helper_method :facebook_session
  
  def index
    render :text => "users/index"
  end
  
  def show
    @profile_user = User.find(params[:id], :include => {:playlists => :likes}, :order => "playlists.created_at DESC")
    @playlists = @profile_user.playlists
    @liked_playlists = Playlist.all :include => [:likes, :user], :conditions => ["likes.user_id = ?", @profile_user], :order => "likes.created_at DESC"
  end
end
