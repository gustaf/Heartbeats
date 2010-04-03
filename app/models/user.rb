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
    p @fb_friends
    User.all({:conditions => ["uid IN (?)", @fb_friends]})
  end

  #for bands in town
  def top50artists
    artists = playlists.sort{|a,b| b.created_at <=> a.created_at}.map{|p| p.artists}.flatten.uniq
    return artists[0...50] #if artists.size >= 50
    followees_playlists = followees.map{|f| f.playlists}.flatten
    artists += followees_playlists.sort{|a,b| b.created_at <=> a.created_at}.map{|p| p.artists}.flatten.uniq
    artists[0...50]
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
