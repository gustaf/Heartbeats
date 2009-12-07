class Likes < ActiveRecord::Migration
  def self.up
    create_table :likes do |t|
      t.integer :user_id
      t.integer :playlist_id
      t.timestamps
    end
    add_index :likes, [:user_id, :playlist_id], :unique => true
  end

  def self.down
    drop_table :likes
    remove_index :likes, [:user_id, :playlist_id]
  end
end
