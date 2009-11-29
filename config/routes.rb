ActionController::Routing::Routes.draw do |map|
  map.root :controller => 'home'
  
  map.resources :users do |user|
    user.resources :plyalists
  end
  
  map.resources :playlists

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
