class CreateFbFollowees < ActiveRecord::Migration
  def self.up
    create_table :fb_followees do |t|
      t.integer :uid, :limit => 15
      t.references :user

      t.timestamps
    end
  end

  def self.down
    drop_table :fb_followees
  end
end
