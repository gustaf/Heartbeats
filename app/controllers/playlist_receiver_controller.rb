class PlaylistReceiverController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def index
    @post = request.raw_post
    logger.info "playlist receiver received: #@post"
    render :text => "ok"
  end

end
