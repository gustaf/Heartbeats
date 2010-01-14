class CreateHbFollowees < ActiveRecord::Migration
  def self.up
    create_table :hb_followees do |t|
      t.integer :uid, :limit => 15
      t.references :user

      t.timestamps
    end
  end

  def self.down
    drop_table :hb_followees
  end
end
