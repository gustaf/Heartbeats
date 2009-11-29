class User < ActiveRecord::Base
  validates_presence_of :uid
  validates_uniqueness_of :uid
  has_many :playlists

  class << self
    def find_or_create(uid)
      user = first({:conditions => {:uid => uid}})
      return user if user
      user = new(:uid => uid)
      user.save!
      user
    end
  end
end
