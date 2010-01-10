class CreateTrackArtistJoinTable < ActiveRecord::Migration
  def self.up
    create_table :artists_tracks, :id => false do |t|
      t.integer :track_id
      t.integer :artist_id
    end
  end

  def self.down
    drop_table :artists_tracks
  end
end
