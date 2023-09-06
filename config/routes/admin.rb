# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq/cron/web'
require 'sidekiq_unique_jobs/web'

class AdminConstraint
  def matches?(request)
    return false if request.session[:current_admin_id].blank?

    Administrator.find_by(id: request.session[:current_admin_id]).present?
  end
end

namespace :admin do
  # sidekiq
  mount Sidekiq::Web, at: 'sidekiq', constraints: AdminConstraint.new
  # pghero
  mount PgHero::Engine, at: 'pghero'
  # exception
  mount ExceptionTrack::Engine => '/exception-track'

  root to: 'overview#index'

  get 'login', to: 'login#new', as: :login
  post 'login', to: 'login#create'
  get 'logout', to: 'login#delete', as: :logout

  resources :sessions, only: %i[index]
  resources :users, only: %i[index show], param: :uid do
    post :validate
    post :unvalidate
    post :block
    post :unblock
  end

  resources :collections, only: %i[index show]

  resources :articles, only: %i[index show], param: :uuid do
    post :block
    post :unblock
  end

  resources :comments, only: %i[index] do
    post :delete
    post :undelete
  end

  resources :orders, only: %i[index show]
  resources :pre_orders, only: %i[index show], param: :follow_id

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

  resources :bonuses, only: %i[index create new] do
    post :deliver
  end

  resources :wallets do
    get :assets
    get :snapshots
  end

  resources :non_fungible_outputs, only: %i[index show]
  resources :collectibles, only: %i[index show], param: :metahash
  resources :nft_collections, only: %i[index show]
  resources :arweave_transactions, only: %i[index show]
end
