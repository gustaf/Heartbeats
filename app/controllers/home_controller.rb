class HomeController < ApplicationController
  before_filter :set_facebook_session, :ensure_logged_in_and_get_user
  helper_method :facebook_session

  def index
    @friends = [@user] + @user.followees
  end
end
