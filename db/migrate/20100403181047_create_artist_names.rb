class CreateArtistNames < ActiveRecord::Migration
  def self.up
    create_table :artist_names do |t|
      t.string :name
      t.references :user

      t.timestamps
    end

    say "this will take a long time, #{User.count} users in total"
    User.all.each do |u|
      say u.id
      artists = Artist.all(:limit => 50, :joins => {:tracks => {:playlists => :user}}, :conditions => ["users.id = ?", u.id], :select => "DISTINCT(artists.name)", :order => "playlists.created_at DESC")
      artists.each do |a|
        ArtistName.new(:name => a.name, :user_id => u.id).save
      end
    end
  end

  def self.down
    drop_table :artist_names
  end
end
