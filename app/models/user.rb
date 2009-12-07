class User < ActiveRecord::Base
  validates_presence_of :uid
  validates_uniqueness_of :uid
  has_many :playlists
  has_many :likes
  
  def like(playlist)
    unless likes?(playlist)
      Like.create(:user => self, :playlist => playlist)
    end
  end
  
  def likes?(playlist)
    !Like.find(:first, :conditions => ["user_id = ? and playlist_id = ?", self, playlist]).blank?
  end
  
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
