# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq/cron/web'

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
