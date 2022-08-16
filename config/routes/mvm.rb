# frozen_string_literal: true

namespace :mvm do
  resource :faucet, only: :create
  resource :swap, only: :create
end
