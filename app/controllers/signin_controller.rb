class SigninController < ApplicationController
  before_filter :set_facebook_session
  helper_method :facebook_session

  def index
    if facebook_session && !facebook_session.expired?
      redirect_to root_url
    end
  end

end
