# frozen_string_literal: true

namespace :grover do
  resources :collections, only: %i[] do
    get :cover
  end
end
