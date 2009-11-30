class HomeController < ApplicationController
  before_filter :set_facebook_session, :ensure_logged_in_and_get_user
  helper_method :facebook_session

  def index
    @new_playlist = Playlist.new
    
    @my_playlists = Playlist.find_all_by_user_id(@user.id)
    
    friends = facebook_session.user.friends
    friends_in_app = User.find(:all, :conditions => ["uid IN (?)", friends.map{|f| f.uid}], :include => :playlists)
    @friends_in_left_col = []
    @friends_in_right_col = []
    i = 0
    friends_in_app.each do |friend|
      if (i = i ^ 1) == 1
        @friends_in_left_col << friend
      else
        @friends_in_right_col << friend
      end
    end
  end
end
