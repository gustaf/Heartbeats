class AddFbuidToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :fb_uid, :string
  end

  def self.down
    remove_column :users, :fb_uid
  end
end
