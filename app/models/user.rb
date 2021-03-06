class User < ActiveRecord::Base
  validates_presence_of :uid
  validates_uniqueness_of :uid
  has_many :playlists
  has_many :likes
  
  attr_writer :fb_friends
  
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

  def friends
    User.all(:include => {:playlists => :likes}, :conditions => ["uid IN (?)", @fb_friends], :order => "coalesce(playlists.created_at,'-infinity') DESC")
    #coalesce ugly work around to make postgres putting the NULLS LAST without breaking in mysql
  end

  #for bands in town
  def top50artists
    ArtistName.top50(self)
  end
  
  class << self
    def find_or_create(uid)
      user = first(:conditions => {:uid => uid}, :include => {:playlists => :likes}, :order => "playlists.created_at DESC")
      return user if user
      user = new(:uid => uid)
      user.save!
      user
    end
  end
end
