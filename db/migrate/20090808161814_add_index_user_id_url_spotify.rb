class AddIndexUserIdUrlSpotify < ActiveRecord::Migration
  def self.up
    add_index :playlists, [:user_id, :url_spotify], :unique => true
  end

  def self.down
    remove_index :playlists, [:user_id, :url_spotify]
  end
end
