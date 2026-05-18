Rails.application.routes.draw do
  root "clubs#index"

  resources :matches, only: [:index, :show] do
    member  { post :simulate }
    collection { post :simulate_all }
  end

  resources :clubs, only: [:index, :show]

  resource :game_mode, only: [:new, :create, :destroy]

  # Health check (Rails 8 default)
  get "up" => "rails/health#show", as: :rails_health_check
end