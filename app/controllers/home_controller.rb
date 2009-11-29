class HomeController < ApplicationController
  before_filter :set_facebook_session, :ensure_logged_in_and_get_user
  helper_method :facebook_session

  def index
    @new_playlist = Playlist.new
    
    @my_playlists = Playlist.find_all_by_user_id(@user.id)
    
    friends = facebook_session.user.friends
    @friends_in_app = User.find(:all, :conditions => ["uid IN (?)", friends.map{|f| f.uid}], :include => :playlists)
  end
end
