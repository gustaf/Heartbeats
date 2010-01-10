class AddDataFetchedCollaborativeToPlaylist < ActiveRecord::Migration
  def self.up
    add_column :playlists, :collaborative, :integer
    add_column :playlists, :data_requested_at, :datetime
    add_column :playlists, :data_updated_at, :datetime
  end

  def self.down
    remove_column :playlists, :data_updated_at
    remove_column :playlists, :data_requested_at
    remove_column :playlists, :collaborative
  end
end
