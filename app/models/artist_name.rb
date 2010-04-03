class ArtistName < ActiveRecord::Base
  belongs_to :user
  validates_uniqueness_of :name, :scope => [:user_id]

  class << self
    def top50(user)
      all(:conditions => {:user_id => user}, :limit => 50, :order => "updated_at DESC", :select => :name).map {|a| a.name}
    end
  end
end
