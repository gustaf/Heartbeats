class MissingPlaylistsController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def index
    playlists = Playlist.all(:conditions => ["title IS NULL"])
    urls = playlists.select{|p| p.is_proper_playlist?}.map{|p| p.url_spotify}
    
    render :text => urls.shuffle.join("\n")
  end
end
