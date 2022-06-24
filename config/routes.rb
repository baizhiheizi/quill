# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq/cron/web'

class AdminConstraint
  def matches?(request)
    return false if request.session[:current_admin_id].blank?

    Administrator.find_by(id: request.session[:current_admin_id]).present?
  end
end

Rails.application.routes.draw do
  post '/graphql', to: 'graphql#execute'

  get 'login', to: 'sessions#new', as: :login
  post '/auth/mixin/callback', to: 'sessions#mixin'
  post '/auth/fennec/callback', to: 'sessions#fennec'
  post '/auth/mvm/callback', to: 'sessions#mvm'
  get 'logout', to: 'sessions#delete', as: :logout
  post 'nounce', to: 'sessions#nounce'

  get 'landing', to: 'landing#index', as: :landing
  get 'search', to: 'search#index', as: :search

  # health check for render.com
  get 'healthz', to: 'healthz#index', as: :healthz

  # error pages
  get '/404', to: 'errors#not_found'
  get '/406', to: 'errors#not_acceptable'
  get '/422', to: 'errors#unprocessable_entity'
  get '/500', to: 'errors#internal_server_error'

  root to: 'home#index'

  resources :view_modals, only: %i[create]

  resources :articles, except: %i[destroy], param: :uuid do
    put :update_content
    resources :comments, only: %i[index]
  end
  resources :upvoted_articles, only: %i[update destroy], param: :uuid
  resources :downvoted_articles, only: %i[update destroy], param: :uuid
  resources :comments, only: %i[create]
  resources :upvoted_comments, only: %i[update destroy]
  resources :downvoted_comments, only: %i[update destroy]
  post '/articles/preview', to: 'articles#preview', as: :preview_article
  resources :article_references, only: %i[index], default: { format: :json }
  resources :payments, only: %i[create]

  resources :block_users, only: %i[create destroy], param: :uid
  resources :subscribe_users, only: %i[create destroy], param: :uid
  resources :subscribe_articles, only: %i[create destroy], param: :uuid
  resources :subscribe_tags, only: %i[create destroy]

  resources :tags, only: %i[index]
  resources :users, only: :show, param: :uid
  resources :users, only: [], module: 'users', param: :uid do
    resources :articles, only: %i[index]
    resources :comments, only: %i[index]
    resources :subscribe_users, only: %i[index]
    resources :subscribe_by_users, only: %i[index]
  end
  resources :transfers, only: %i[index]
  get '/transfers/stats', to: 'transfers#stats'

  namespace :dashboard do
    resources :settings, only: %i[index]
    resources :articles, only: %i[index show destroy], param: :uuid
    resources :published_articles, param: :uuid, only: %i[update destroy]
    resources :comments, only: %i[index]
    resources :subscriptions, only: %i[index]
    resources :block_users, only: %i[index]
    resources :subscribe_users, only: %i[index]
    resources :subscribe_by_users, only: %i[index]
    resources :subscribe_articles, only: %i[index]
    resources :subscribe_tags, only: %i[index]
    resources :transfers, only: %i[index]
    resources :orders, only: %i[index]
    resources :payments, only: %i[index]
    resources :swap_orders, only: %i[index]
    resources :notifications, only: %i[index]
    resources :read_notifications, only: %i[create update]
    resources :deleted_notifications, only: %i[create]
    resources :notification_settings, only: %i[update]
    resources :access_tokens, only: %i[index create destroy]
    root to: 'home#index'
  end

  namespace :admin do
    # sidekiq
    mount Sidekiq::Web, at: 'sidekiq', constraints: AdminConstraint.new
    # pghero
    mount PgHero::Engine, at: 'pghero'
    # exception
    mount ExceptionTrack::Engine => '/exception-track'

    root to: 'overview#index'

    get 'login', to: 'sessions#new', as: :login
    post 'login', to: 'sessions#create'
    get 'logout', to: 'sessions#delete', as: :logout

    resources :users, only: %i[index show], param: :uid do
      post :ban
      post :unban
    end
    resources :articles, only: %i[index show], param: :uuid do
      post :block
      post :unblock
    end
    resources :comments, only: %i[index] do
      post :delete
      post :undelete
    end
    resources :orders, only: %i[index show]
    resources :swap_orders, only: %i[index show]
    resources :payments, only: %i[index show]
    resources :transfers, only: %i[index show] do
      post :process_now
    end
    resources :mixin_network_snapshots, only: %i[index show] do
      post :process_now
    end
    resources :mixin_network_users, only: %i[index show]
    resources :statistics, only: %i[index]
    resources :bonuses, only: %i[index create] do
      post :deliver
    end
    resources :wallets do
      get :assets
      get :snapshots
    end
    resources :view_modals, only: %i[create]
  end

  namespace :api, defaults: { format: :json } do
    resources :articles, only: %i[index show create], param: :uuid
    resources :files, only: %i[show], param: :hash

    get 'valid_user_filter', to: 'valid_users#filter'
  end

  namespace :widget do
    resources :articles, only: :index
  end
end
