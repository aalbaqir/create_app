Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Health check endpoint for uptime monitoring
  get "up" => "rails/health#show", as: :rails_health_check
  
  # Upload route for the media controller
  post '/upload', to: 'media#upload'

  post '/generate_new_caption', to: 'media#generate_new_caption'

  # Defines the root path route ("/")
  # root "posts#index"
end
