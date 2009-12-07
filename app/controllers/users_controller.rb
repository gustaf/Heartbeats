class UsersController < ApplicationController
  before_filter :set_facebook_session, :ensure_logged_in_and_get_user
  
  def index
    render :text => "users/index"
  end
  
  def show
    @profile_user = User.find(params[:id])
  end

end