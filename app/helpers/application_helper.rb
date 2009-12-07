# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def user_pic(user)
    link_to fb_profile_pic(user.uid, :size => :square, :linked => "false"), user_url(user), :class => "user_pic"
  end
  
  def user_name(user)
    link_to fb_name(user.uid, :useyou => "false", :linked => "false"), user_url(user), :class => "user_name"
  end
end
