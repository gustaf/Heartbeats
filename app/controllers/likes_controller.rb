class LikesController < ApplicationController
  before_filter :set_facebook_session, :ensure_logged_in_and_get_user
  
  def create
    render :text => "liked"
  end

end