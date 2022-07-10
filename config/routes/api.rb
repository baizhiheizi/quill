# frozen_string_literal: true

namespace :api, defaults: { format: :json } do
  resources :articles, only: %i[index show create], param: :uuid
  resources :files, only: %i[show], param: :hash

  get 'valid_user_filter', to: 'valid_users#filter'
end
