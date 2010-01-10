class Track < ActiveRecord::Base
  has_and_belongs_to_many :playlists
  has_and_belongs_to_many :artists
end
