class HomeController < ApplicationController
  before_filter :set_facebook_session, :ensure_logged_in_and_get_user
  helper_method :facebook_session

  def index
    friends = facebook_session.user.friends
    friends << facebook_session.user
    @playlists = {}
    friends.each do |friend|
      ps = Playlist.find_by_uid(friend.id)
      @playlists[friend] = ps if ps && !ps.empty?
    end
  end

  def create
    playlist = Playlist.new(:user => @me, :url => params[:url])

    success = false
    begin
      success = playlist.save
    rescue ActiveRecord::StatementInvalid
      success = playlist.touch
    end

    if success
      redirect_to "/home"
    else
      raise playlist.errors.inspect
    end
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

    @me = User.fb_uid(facebook_session.user.id)
  end
end
