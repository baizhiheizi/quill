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
  mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/graphql' if Rails.env.development?
  post '/graphql', to: 'graphql#execute'

  get 'login', to: 'sessions#new', as: :login
  match '/auth/mixin/callback', to: 'sessions#create', via: %i[get post]
  get 'logout', to: 'sessions#delete', as: :logout

  get 'landing', to: 'landing#index', as: :landing

  resources :view_modals, only: %i[create]

  resources :articles, except: %i[destroy], param: :uuid do
    resources :comments, only: %i[index]
  end
  resources :upvoted_articles, only: %i[update destroy], param: :uuid
  resources :downvoted_articles, only: %i[update destroy], param: :uuid
  resources :comments, only: %i[create]
  resources :upvoted_comments, only: %i[update destroy]
  resources :downvoted_comments, only: %i[update destroy]
  post '/articles/preview', to: 'articles#preview', as: :preview_article
  resources :published_articles, param: :uuid, only: %i[update destroy]
  resources :article_references, only: %i[index], default: { format: :json }
  resources :payments, only: %i[create]
  resources :subscribe_users, only: %i[create destroy], param: :uid
  resources :subscribe_articles, only: %i[create destroy], param: :uuid
  resources :subscribe_tags, only: %i[create destroy]

  resources :tags, only: %i[index show]
  resources :users, only: :show, param: :uid do
    resources :subscribe_users, only: %i[index]
    resources :subscribe_by_users, only: %i[index]
  end

  root to: 'home#index'

  namespace :dashboard do
    resources :settings, only: %i[index]
    resources :articles, only: %i[index destroy], param: :uuid
    resources :comments, only: %i[index]
    resources :subscriptions, only: %i[index]
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
    get 'logout', to: 'sessions#delete', as: :logout

    # sidekiq
    mount Sidekiq::Web, at: 'sidekiq', constraints: AdminConstraint.new

    # pghero
    mount PgHero::Engine, at: 'pghero'

    # exception
    mount ExceptionTrack::Engine => '/exception-track'

    root to: 'overview#index'
    get '*path' => 'overview#index'
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
