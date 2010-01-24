class CreateTracks < ActiveRecord::Migration
  def self.up
    create_table :tracks do |t|
      t.string :name
      t.string :uri, :null => false
      t.string :album
      t.integer :popularity
      t.integer :duration

      t.timestamps
    end
    add_index :tracks, :uri, :unique => true
  end

  def self.down
    remove_index :tracks, :uri
    drop_table :tracks
  end
end
