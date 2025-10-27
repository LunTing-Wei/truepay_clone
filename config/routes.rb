Rails.application.routes.draw do
  devise_for :members

  get "up" => "rails/health#show", as: :rails_health_check

  resources :tickets, only: [:index] do
    collection do
      get :scan
      post :verify
    end
  end

  resources :products
  resources :stores, only: [:show]
  resources :orders, only: [:new, :create, :show] do
    member do
      post :pay
      post :linepay_request
      get :linepay_confirm
    end
  end
  root "tickets#index"
end
