class AddUrlSpotifyToPlaylist < ActiveRecord::Migration
  def self.up
    add_column :playlists, :url_spotify, :string, :null => false
    add_index :playlists, :url_spotify, :unique => true
  end

  def self.down
    remove_column :playlists, :url_spotify
    remove_index :playlists, :url_spotify
  end
end
