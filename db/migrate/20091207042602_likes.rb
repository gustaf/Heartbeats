class Likes < ActiveRecord::Migration
  def self.up
    create_table :likes do |t|
      t.integer :user_id
      t.integer :playlist_id
      t.timestamps
    end
  end

  def self.down
    drop_table :likes
  end
end
