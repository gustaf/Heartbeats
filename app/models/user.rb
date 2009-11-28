class User < ActiveRecord::Base
  validates_presence_of :fb_uid
  validates_uniqueness_of :fb_uid

  class << self
    def fb_uid(fb_uid)
      user = first({:conditions => {:fb_uid => fb_uid}})
      return user if user
      user = new(:fb_uid => fb_uid)
      user.save!
      user
    end
  end
end
