task :cron => :environment do
  update_playlists
end

def update_playlists
  puts "updating playlists..."
  Playlist.all(:order => "data_requested_at ASC").each do |p|
    puts "requesting data for playlist #{p.url_spotify}"
    p.lookup!
    sleep 1
  end
  puts "updating playlists...done"
end
