class CreatePlaylistTrackJoinTable < ActiveRecord::Migration
  def self.up
    create_table :playlists_tracks, :id => false do |t|
      t.integer :playlist_id
      t.integer :track_id
    end
  end

  def self.down
    drop_table :playlists_tracks
  end
end
