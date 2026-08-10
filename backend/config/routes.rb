Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  scope :api, defaults: { format: :json } do
    resources :projects, only: [ :index, :show, :create ] do
      resources :tickets, only: [ :show, :new, :create, :edit, :update, :destroy ] do
        resources :comments, only: [ :create, :update, :destroy ]
      end
    end
    resources :users, only: [ :create ] do
      post :switch, on: :collection
    end
  end

  resources :projects, only: [ :index, :show, :create ], defaults: { format: :json } do
    resources :tickets, only: [ :show, :new, :create, :edit, :update, :destroy ], defaults: { format: :json } do
      resources :comments, only: [ :create, :update, :destroy ], defaults: { format: :json }
    end
  end
  resources :users, only: [ :create ], defaults: { format: :json } do
    post :switch, on: :collection
  end

  # Defines the root path route ("/")
  root "projects#index", defaults: { format: :json }
end
