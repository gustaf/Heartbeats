require 'bandsintown'
 
class HomeController < ApplicationController
  before_filter :set_facebook_session, :ensure_logged_in_and_get_user
  helper_method :facebook_session
 
  def index
    @friends = [@user] + @user.friends
    Bandsintown.app_id = "heartbeats"
    begin
      @events = Bandsintown::Event.recommended({
        :artists => @user.top50artists,
        :location => request.remote_ip
       #:location => "212.162.1.95"
      })
    rescue Bandsintown::APIError
      @events = []
    end
  end

  def aboutus
  end

  def help
  end

  def contact
  end

  def terms
  end

  def privacy
  end
end
