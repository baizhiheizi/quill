# frozen_string_literal: true

namespace :dashboard do
  root to: "home#index"

  # Canonical grouped-section landing routes (rail/tabbar shell).
  get :write, to: "home#write"
  get :read, to: "home#read"
  get :finances, to: "home#finances"
  get :account, to: "home#account"

  # Legacy paths kept resolving per FR-030/SC-008 — redirect to the new
  # canonical equivalent above, preserving `tab` where meaningful.
  get :settings, to: "home#redirect_settings"
  get :readings, to: "home#redirect_readings"
  get :authorings, to: "home#redirect_authorings"
  get :stats, to: "home#redirect_stats"

  resources :listed_collections, only: %i[new update]
  resources :hidden_collections, only: %i[new update]
  resources :collections
  resources :articles, only: %i[index show], param: :uuid
  resources :published_articles, param: :uuid, only: %i[new update destroy]
  resources :deleted_articles, param: :uuid, only: %i[new update]
  resources :comments, only: %i[index]
  resources :subscriptions, only: %i[index]
  resources :block_users, only: %i[index]
  resources :subscribe_users, only: %i[index]
  resources :subscribe_articles, only: %i[index]
  resources :subscribe_tags, only: %i[index]
  resources :orders, only: %i[index]
  resources :payments, only: %i[index]
  resources :notifications, only: %i[index show]
  resources :transfers, only: %i[index]
  get "/transfers/stats", to: "transfers#stats", as: :transfers_stats

  resources :read_notifications, only: %i[new create update]
  resources :deleted_notifications, only: %i[new create]
  resources :notification_settings, only: %i[update]
  resource :profile_setting, only: %i[edit update]

  get "email_verify", to: "profile_settings#verify_email"

  resources :access_tokens, only: %i[index create destroy]
end
