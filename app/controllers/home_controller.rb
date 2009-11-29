class HomeController < ApplicationController
  before_filter :set_facebook_session, :ensure_logged_in_and_get_user
  helper_method :facebook_session

  def index
    @my_playlists = Playlist.find_all_by_user_id(@user.id)
    
    friends = facebook_session.user.friends
    @friends_in_app = User.find(:all, :conditions => ["uid IN (?)", friends.map{|f| f.uid}], :include => :playlists)
  end

  def test
    @test = 'high'
    @fbuid= facebook_session.user.id
  end

  def create
    playlist = Playlist.create(:user => @user, :url => params[:url])

    if playlist
      flash[:playlist_added] = UserPublisher.create_playlist_added(facebook_session.user)
    end
    
    redirect_to "/home"
  end

# DELETE PLAYLIST    
  def delete 
    id = params[:id]
    playlist = Playlist.find(id)
    playlist.destroy 
    
    redirect_to "/home"  
  end
   
  private
  def ensure_logged_in_and_get_user
    if !facebook_session || facebook_session.expired?
      redirect_to(:controller => "signin")
      return
    end

    begin
      facebook_session.user.name
    rescue Facebooker::Session::SessionExpired
      clear_fb_cookies!
      clear_facebook_session_information
      redirect_to(:controller => "signin")
      return
    end

    @user = User.find_or_create(facebook_session.user.id)
  end
end
