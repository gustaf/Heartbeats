require 'xml'

class PlaylistReceiverController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def index
    self.class.parse_xml(request.raw_post)
    render :text => request.inspect
  end

  class << self
    def parse_xml(xml)
      xml = XML::Document.string(xml)

      uri = xml.find_first("/playlist/@uri").value
      pls = Playlist.all(:conditions => ["url_spotify = ?", uri])

      pls.each do |pl|
        p = xml.find_first("/playlist")
        pl.title = p.attributes["name"]
        pl.collaborative = p.attributes["collaborative"] == "yes" ? 1 : 0
        pl.data_updated_at = DateTime.now

        pl.tracks = xml.find("/playlist/track").map do |t|
          track = Track.first(:conditions => ["uri = ?", t.attributes["uri"]]) || Track.new
          track.uri = t.attributes["uri"]
          track.name = t.attributes["name"]
          track.popularity = t.attributes["popularity"]
          track.duration = t.attributes["duration"]
          track.album = t.attributes["album"]
          track.artists = t.find("artist").map do |a|
            artist = Artist.first(:conditions => ["name = ?", a.content])
            unless artist then
              artist = Artist.new
              artist.name = a.content
              artist.save
            end
            artist
          end
          track.save
          track
        end

        pl.save
      end

    end
  end
end
