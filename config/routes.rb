Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  mount ActionCable.server => '/cable'
  # Defines the root path route ("/")
  # root "posts#index"

  namespace :api do
    namespace :v1 do
      # Items de Loyverse
      resources :items, only: [:index, :show] do
        collection do
          get 'modifiers'
        end
      end
      
      # Pagos
      resources :payments, only: [:index, :show] do
        collection do
          post :process_payment_with_token
          post :process_payment_with_method
          get 'user/:user_id', action: :by_user, as: :user
        end
      end

      get 'payments/user/:user_id', to: 'payments#by_user'
      
      # Rutas para Kitchen Orders
      get 'kitchen_orders/pending', to: 'kitchen_orders#pending'
      patch 'kitchen_orders/:id/update_status', to: 'kitchen_orders#update_status'
    end
  end
end
