# frozen_string_literal: true

Rails.application.routes.draw do
  get '/(*path)', to: redirect { |path_params, _request|
                        "https://quill.im/#{path_params[:path]}"
                      },
                  status: 301,
                  constraints: { domain: 'prsdigg.com' }

  draw :admin
  draw :dashboard
  draw :mvm
  draw :api

  get 'login', to: 'sessions#new', as: :login
  get '/auth/mixin/callback', to: 'sessions#mixin'
  get '/auth/fennec/callback', to: 'sessions#fennec'
  get '/auth/mvm/callback', to: 'sessions#mvm'
  get 'logout', to: 'sessions#delete', as: :logout
  post 'nounce', to: 'sessions#nounce'

  get 'landing', to: 'landing#index', as: :landing
  get 'search', to: 'search#index', as: :search

  # health check for render.com
  get 'healthz', to: 'healthz#index', as: :healthz

  # error pages
  get '/404', to: 'errors#not_found'
  get '/406', to: 'errors#not_acceptable'
  get '/422', to: 'errors#unprocessable_entity'
  get '/500', to: 'errors#internal_server_error'

  root to: 'articles#index'

  resources :view_modals, only: %i[create]
  resources :locales, only: %i[create]

  resources :articles, except: %i[destroy], param: :uuid do
    put :update_content
    resources :comments, only: %i[index]
  end
  resources :upvoted_articles, only: %i[update destroy], param: :uuid
  resources :downvoted_articles, only: %i[update destroy], param: :uuid
  resources :comments, only: %i[create]
  resources :upvoted_comments, only: %i[update destroy]
  resources :downvoted_comments, only: %i[update destroy]
  post '/articles/preview', to: 'articles#preview', as: :preview_article
  resources :article_references, only: %i[index], default: { format: :json }
  resources :payments, only: %i[create]

  resources :block_users, only: %i[create destroy], param: :uid
  resources :subscribe_users, only: %i[create destroy], param: :uid
  resources :subscribe_articles, only: %i[create destroy], param: :uuid
  resources :subscribe_tags, only: %i[create destroy]

  resources :tags, only: %i[index]

  resources :currencies, only: %i[index]
  resources :users, only: :show, param: :uid, as: :full_user
  resources :users, only: [], module: 'users', param: :uid do
    resources :articles, only: %i[index]
    resources :comments, only: %i[index]
    resources :subscribe_users, only: %i[index]
    resources :subscribe_by_users, only: %i[index]
  end

  resources :pre_orders, only: %i[create show new], param: :follow_id do
    get :state, default: { format: :json }
  end
  resource :mixpay_pre_order, only: %i[show]

  resources :transfers, only: %i[index]
  get '/transfers/stats', to: 'transfers#stats'

  get '/fair' => 'high_voltage/pages#show', id: 'fair', as: :fair_page
  get '/rules' => 'high_voltage/pages#show', id: 'rules', as: :rules_page

  get '/:uid', to: 'users#show', as: :user
  get '/:uid/:uuid', to: 'articles#show', as: :user_article
end
