class AddTitleToPlaylists < ActiveRecord::Migration
  def self.up
    add_column :playlists, :title, :string
  end

  def self.down
    remove_column :playlists, :title
  end
end
