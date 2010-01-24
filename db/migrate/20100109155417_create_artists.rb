class CreateArtists < ActiveRecord::Migration
  def self.up
    create_table :artists do |t|
      t.string :name, :null => false

      t.timestamps
    end
    add_index :artists, :name, :unique => true
  end

  def self.down
    remove_index :artists, :name
    drop_table :artists
  end
end
