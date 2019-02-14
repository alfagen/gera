Gera::Engine.routes.draw do
  root 'direction_rates#index'
  # get :tables_sizes, to: 'dashboard#tables_sizes'
  resources :payment_systems

  resources :currency_rate_history_intervals, only: [:index]
  resources :direction_rate_history_intervals, only: [:index]

  resources :currencies, only: [:index]
  resources :direction_rates do
    member do
      get :last
    end
  end
  resources :external_rates, only: [:index, :show]
  resources :external_rate_snapshots, only: [:index, :show]
  resources :currency_rates
  resources :currency_rate_modes, only: [:edit, :update, :new, :create]
  resources :currency_rate_mode_snapshots, only: [:index, :edit, :update, :show, :create] do
    member do
      post :activate
    end
  end
  resources :rate_sources
end
