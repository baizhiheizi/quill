# frozen_string_literal: true

namespace :mvm do
  resources :extras, only: :create
  resource :faucet, only: :create
  resource :swap, only: :create
end
