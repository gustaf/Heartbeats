class HbFolloweesController < ApplicationController
  before_filter :set_facebook_session, :ensure_logged_in_and_get_user
  helper_method :facebook_session
  
  def update
    @user.follow!(followee.uid)
    redirect_to followee
  end

  def destroy
    @user.unfollow!(followee.uid)
    redirect_to followee
  end

  private
  def followee
    @followee ||= User.find(params[:id])
  end
end
