# frozen_string_literal: true

namespace :grover do
  resources :collections, only: %i[] do
    get :cover
  end
  resources :articles, only: %i[], param: :uuid do
    get :poster
  end
end
