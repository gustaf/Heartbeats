# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'meta-spotify'

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  protect_from_forgery
end
