ActionController::Routing::Routes.draw do |map|
  map.root :controller => 'home'
  
  map.resources :users
  map.resources :playlists
  map.resources :likes
  map.resources :hb_followees

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end

# See how all your routes lay out with "rake routes"
