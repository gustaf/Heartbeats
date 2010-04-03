# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100403181047) do

  create_table "artist_names", :force => true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "artists", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "artists_tracks", :id => false, :force => true do |t|
    t.integer "track_id"
    t.integer "artist_id"
  end

  create_table "fb_followees", :force => true do |t|
    t.integer  "uid",        :limit => 8
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "hb_followees", :force => true do |t|
    t.integer  "uid",        :limit => 8
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "likes", :force => true do |t|
    t.integer  "user_id"
    t.integer  "playlist_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "playlists", :force => true do |t|
    t.string   "url"
    t.string   "url_spotify",       :null => false
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "title"
    t.integer  "collaborative"
    t.datetime "data_requested_at"
    t.datetime "data_updated_at"
  end

  create_table "playlists_tracks", :id => false, :force => true do |t|
    t.integer "playlist_id"
    t.integer "track_id"
  end

  create_table "tracks", :force => true do |t|
    t.string   "name"
    t.string   "uri",        :null => false
    t.string   "album"
    t.integer  "popularity"
    t.integer  "duration"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.integer  "uid",        :limit => 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
