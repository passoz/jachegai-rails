Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # JaChegai health endpoints (outside /api/v1/)
  get "healthz" => "health#liveness", as: :healthz
  get "readyz" => "health#readiness", as: :readyz

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  # Test routes for BaseController envelope (remove when actual API routes are added)
  namespace :api do
    namespace :v1 do
      # Auth
      post "auth/register" => "auth#register", as: :auth_register
      post "auth/login" => "auth#login", as: :auth_login
      get "auth/me" => "auth#me", as: :auth_me
      post "auth/logout" => "auth#logout", as: :auth_logout

      # Seller onboarding & profile
      post "seller/onboarding" => "seller/onboarding#create", as: :seller_onboarding
      get "seller/profile" => "seller/profile#show", as: :seller_profile
      patch "seller/profile" => "seller/profile#update", as: :seller_profile_update
      get "seller/settings" => "seller/settings#show", as: :seller_settings
      patch "seller/settings" => "seller/settings#update", as: :seller_settings_update

      # Seller catalog & inventory
      namespace :seller do
        resources :categories, only: [ :index, :show, :create, :update, :destroy ] do
          collection do
            put "order" => "categories#reorder"
          end
        end
        resources :products, only: [ :index, :show, :create, :update, :destroy ] do
          member do
            post "activate"
            post "deactivate"
          end
        end
        get "inventory" => "inventory#index"
        patch "inventory/:product_id" => "inventory#update"
        resources :orders, only: [ :index, :show ] do
          member do
            post "accept"
            post "reject"
            post "preparing"
            post "ready"
          end
        end
      end

      # Admin moderation
      namespace :admin do
        get "observability/summary" => "observability#summary"
        get "observability/requests" => "observability#requests"
        get "observability/orders" => "observability#orders"
        get "observability/jobs" => "observability#jobs"
        get "dashboard" => "dashboard#show"
        resources :invoices, only: [ :index, :show ] do
          collection do
            post "generate"
          end
        end
        resources :settings, only: [ :index, :create ]
        resources :users, only: [ :index, :show ] do
          member do
            post "disable"
            post "enable"
          end
        end
        resources :sellers, only: [ :index, :show ] do
          member do
            post "approve" => "sellers#approve"
            post "reject" => "sellers#reject"
            post "suspend" => "sellers#suspend"
            post "reinstate" => "sellers#reinstate"
          end
        end
        resources :couriers, only: [ :index, :show ] do
          member do
            post "approve" => "couriers#approve"
            post "reject" => "couriers#reject"
            post "suspend" => "couriers#suspend"
            post "reinstate" => "couriers#reinstate"
          end
        end
        resources :tickets, only: [ :index, :show ] do
          member do
            post "messages" => "tickets#create_message"
            post "start_progress" => "tickets#start_progress"
            post "resolve" => "tickets#resolve"
            post "reopen" => "tickets#reopen"
            post "close" => "tickets#close"
          end
        end
        resources :payments, only: [ :index, :show ] do
          member do
            post "confirm"
          end
        end
        resources :orders, only: [ :index, :show ] do
          member do
            post "cancel"
          end
        end
      end

      # Courier Experience
      namespace :courier do
        post "onboarding" => "onboarding#create"
        get "profile" => "profile#show"
        patch "profile" => "profile#update"
        patch "availability" => "availability#update"
        get "orders/eligible" => "orders#eligible"
        get "orders/active" => "orders#active"
        get "orders/history" => "orders#history"
        post "orders/:id/accept" => "orders#accept"
        post "orders/:id/pickup" => "orders#pickup"
        post "orders/:id/deliver" => "orders#deliver"
        post "location" => "locations#create"
        get "stats" => "stats#show"
      end

      # Customer Experience
      namespace :customer do
        get "profile" => "profile#show"
        patch "profile" => "profile#update"
        get "addresses" => "addresses#index"
        post "addresses" => "addresses#create"
        get "addresses/:id" => "addresses#show"
        patch "addresses/:id" => "addresses#update"
        delete "addresses/:id" => "addresses#destroy"
        post "addresses/:id/default" => "addresses#make_default"
        resources :favorites, only: [ :index, :create, :destroy ]
        resource :cart, only: [ :show, :destroy ] do
          post "items" => "cart_items#create"
          patch "items/:id" => "cart_items#update"
          delete "items/:id" => "cart_items#destroy"
          post "handoff" => "cart_items#handoff"
        end
        post "checkout" => "checkouts#create"
        post "orders/:id/cancel" => "orders#cancel"
        get "orders/:id/tracking" => "tracking#show"
        resources :tickets, only: [ :index, :show, :create ] do
          post "messages" => "tickets#create_message", on: :member
        end
      end

      # Public discovery
      namespace :public do
        resources :sellers, only: [ :index, :show ] do
          resources :products, only: [ :index ], controller: "products"
        end
        resources :products, only: [ :show ]

        resource :cart, only: [ :show, :destroy ] do
          post "items" => "cart_items#create"
          patch "items/:id" => "cart_items#update"
          delete "items/:id" => "cart_items#destroy"
        end
      end

      if Rails.env.test?
        get "test/show" => "test_api#show", as: :test_api_show
        get "test/not_found" => "test_api#raise_not_found", as: :test_api_raise_not_found
        get "test/internal_error" => "test_api#raise_internal_error", as: :test_api_raise_internal_error
        post "test/echo" => "test_api#echo", as: :test_api_echo
        get "test/echo" => "test_api#echo_get", as: :test_api_echo_get
        post "test/protected" => "test_api#protected_create", as: :test_api_test_protected
      end
    end
  end
end
