# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'meta-spotify'
#require 'ar-extensions'

class ApplicationController < ActionController::Base
  before_filter :check_uri
  
  helper :all # include all helpers, all the time

  protect_from_forgery
  
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
  
  def check_uri
    if /^www/.match(request.host)
      new_url=request.protocol
      new_url+=request.host_with_port.sub("www.","")
      new_url+=request.request_uri
      redirect_to new_url
    end
  end
  
  
end

