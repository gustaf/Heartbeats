ActionController::Routing::Routes.draw do |map|
  map.root :controller => 'home'
  
  map.resources :users do |user|
    user.resources :playlists
  end
  
  map.resources :playlists

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end

# See how all your routes lay out with "rake routes"
