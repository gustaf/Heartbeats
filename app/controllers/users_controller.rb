class UsersController < ApplicationController
  before_filter :set_facebook_session, :ensure_logged_in_and_get_user
  helper_method :facebook_session
  
  def index
    render :text => "users/index"
  end
  
  def show
    @profile_user = User.find(params[:id])
    @friends = @profile_user.followees
    @follows = ! @user.hb_followees.select{|hb| hb.uid == @profile_user.uid}.empty?
    @show_follow_button = @user.fb_followees.select{|fb| fb.uid == @profile_user.uid}.empty?
  end
end
