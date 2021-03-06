Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    registrations: 'users/registrations'
  }
  devise_scope :user do
    get 'addresses', to: 'users/registrations#new_address'
    post 'addresses', to: 'users/registrations#create_address'
  end
  root 'items#index'
  
  resources :credit_cards, only: [:new,:show] do
    collection do
      post 'show', to: 'credit_cards#show'
      post 'pay', to: 'credit_cards#pay'
      post 'delete', to: 'credit_cards#delete'
    end
  end
  
  resources :users do
    member do
      get 'likes'
    end
    #member do
     # end
      member do
        get :sell_transaction
        get :sold
        get :selling
        get :bought
        get :buy_transaction
        get :support
        get :logout
        get :address
        scope :support do
            get :registration_support
            get :defect_support
            get :trouble_support
            get :request_support
            get :evaluation_support
            get :buy_support
            get :withdraw_support
            get :other_support
        end
      end
    end
    resources :items do
      member do
        get 'buy', to: 'items#buy'
        post 'pay', to: 'items#pay'
        get  'done', to: 'items#done'
        post :evaluate
        post :evaluate_delete
        get :buy
        get :get_category_children, defaults: { format: 'json' }
        get :get_category_grandchildren, defaults: { format: 'json' }
        get :get_item_size, defaults: { format: 'json' }
      end
      collection do
        get :get_category_children, defaults: { format: 'json' }
        get :get_category_grandchildren, defaults: { format: 'json' }
        get :get_item_size, defaults: { format: 'json' }
        get :get_item_fee, defaults: { format: 'json' }
        get :search
      end
      resources :favorites do
        member do
          post '/favorite/:item_id', to: 'favorites#create', as: 'like'
          delete '/favorite/:item_id', to: 'favorites#destroy', as: 'unlike'
        end
      end
      resources :comments, only: :create
    end
    resources :categories do
      collection do
        get :get_toppage_category, defaults: { format: 'json' }
        get :category_scroll, defaults: { format: 'json' }
      end
    end
    
  end