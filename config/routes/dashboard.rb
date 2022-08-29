# frozen_string_literal: true

namespace :dashboard do
  resources :settings, only: %i[index]

  resources :articles, only: %i[index show], param: :uuid
  resources :published_articles, param: :uuid, only: %i[new update destroy]
  resources :deleted_articles, param: :uuid, only: %i[new update]

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

  resources :read_notifications, only: %i[new create update]
  resources :deleted_notifications, only: %i[new create]
  resources :notification_settings, only: %i[update]
  resource :profile_setting, only: %i[edit update]

  get 'email_verify', to: 'profile_settings#verify_email'

  resources :access_tokens, only: %i[index create destroy]
  resource :destination, only: %i[show] do
    get :deposit
  end
  root to: 'home#index'
end
