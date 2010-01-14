class User < ActiveRecord::Base
  validates_presence_of :uid
  validates_uniqueness_of :uid
  has_many :playlists
  has_many :likes
  has_many :fb_followees
  has_many :hb_followees
  
  def like(playlist)
    unless likes?(playlist)
      Like.create(:user_id => id, :playlist_id => playlist.id)
    end
  end
  
  def unlike(playlist)
    like = like_for(playlist)
    like.destroy if like
  end
  
  def like_for(playlist)
    Like.find(:first, :conditions => ["user_id = ? and playlist_id = ?", self, playlist])
  end
  
  def likes?(playlist)
    !like_for(playlist).blank?
  end

  def followees
    followee_uids = fb_followees.map{|fb| fb.uid} + hb_followees.map{|hb| hb.uid}
    followee_uids.uniq!
    User.find(:all, :conditions => ["uid IN (?)", followee_uids], :include => :playlists)
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
