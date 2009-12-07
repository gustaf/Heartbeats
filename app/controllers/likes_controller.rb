class LikesController < ApplicationController
  before_filter :set_facebook_session, :ensure_logged_in_and_get_user
  helper_method :facebook_session
  
  def create
    playlist = Playlist.find(params["playlist_id"])
    @user.like(playlist)
    redirect_to playlist_url(playlist)
  end
  
  def destroy
    like = Like.find(params[:id])
    like.destroy if like.user_id == @user.id
    redirect_to playlist_url(like.playlist_id)
  end

end