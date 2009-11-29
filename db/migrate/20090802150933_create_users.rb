class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string  :id
      t.integer :uid, :limit => 8
      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
