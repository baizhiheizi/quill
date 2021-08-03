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

  resources :articles, only: %i[show index], param: :uuid
  resources :tags, only: :show

  root to: 'home#index'

  namespace :dashboard do
    root to: 'overview#index'
    get '*path' => 'overview#index'
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

  get '*path' => 'home#index'
end
