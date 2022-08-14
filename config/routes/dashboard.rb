# frozen_string_literal: true

namespace :dashboard do
  resources :settings, only: %i[index]
  resources :articles, only: %i[index show destroy], param: :uuid
  resources :published_articles, param: :uuid, only: %i[new update destroy]
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
  resource :destination, only: %i[show]
  root to: 'home#index'
end
