class AddUrlSpotifyToPlaylist < ActiveRecord::Migration
  def self.up
    add_column :playlists, :url_spotify, :string, :null => false
    Playlist.delete_all
    add_index :playlists, [:user_id, :url_spotify], :unique => true
  end

  def self.down
    remove_index :playlists, [:user_id, :url_spotify]
    remove_column :playlists, :url_spotify
  end
end
