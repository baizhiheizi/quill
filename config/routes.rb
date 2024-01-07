# frozen_string_literal: true

class SubdomainConstraint
  def matches?(request)
    request.subdomain.present? && request.domain == 'quill.im' && request.subdomain != 'www'
  end
end

Rails.application.routes.draw do
  get '/(*path)', to: redirect { |path_params, _request|
                        "https://quill.im/#{path_params[:path]}"
                      },
                  status: 301,
                  constraints: { domain: /prsdigg.com|bunshow.jp/ }

  draw :admin
  draw :dashboard
  draw :mvm
  draw :api
  draw :grover

  get 'login', to: 'sessions#new', as: :login
  get 'auth/mixin', to: 'sessions#mixin_auth', as: :auth_mixin
  get 'auth/twitter', to: 'sessions#twitter_auth', as: :auth_twitter
  get 'auth/mixin/callback', to: 'sessions#mixin'
  get 'oauth/mixin/callback', to: 'sessions#mixin'
  get 'auth/fennec/callback', to: 'sessions#fennec'
  get 'auth/mvm/callback', to: 'sessions#mvm'
  get 'auth/twitter/callback', to: 'sessions#twitter'
  get 'logout', to: 'sessions#delete', as: :logout
  post 'nonce', to: 'sessions#nonce'

  get 'search', to: 'search#index', as: :search

  # health check
  get 'up', to: 'rails/health#show', as: :rails_health_check

  # error pages
  get '/404', to: 'errors#not_found'
  get '/406', to: 'errors#not_acceptable'
  get '/422', to: 'errors#unprocessable_entity'
  get '/500', to: 'errors#internal_server_error'

  get '/docs', to: redirect('https://docs.quill.im')

  root to: 'home#index'
  get :hot_tags, to: 'home#hot_tags'
  get :active_authors, to: 'home#active_authors'
  get :selected_articles, to: 'home#selected_articles'
  get :more, to: 'home#more'

  resource :locale, only: %i[edit create]
  get '/:locale',
      to: 'locales#show',
      constraints: {
        locale: I18n.available_locales.map(&:to_s)
      }

  resources :collections, only: %i[index show], param: :uuid do
    get :share
  end
  resources :collections, only: [], module: :collections, param: :uuid do
    resources :articles, only: :index
    resources :subscribers, only: :index
  end

  resources :articles, except: %i[destroy], param: :uuid do
    put :update_content
    get :share
    resources :comments, only: %i[index]
  end
  resources :upvoted_articles, only: %i[update destroy], param: :uuid
  resources :downvoted_articles, only: %i[update destroy], param: :uuid
  resources :comments, only: %i[create new]
  resources :upvoted_comments, only: %i[update destroy]
  resources :downvoted_comments, only: %i[update destroy]
  post '/articles/preview', to: 'articles#preview', as: :preview_article
  resources :article_references, only: %i[index], default: { format: :json }

  resources :block_users, only: %i[create destroy new], param: :uid

  resources :subscribe_users, only: %i[new create destroy], param: :uid
  resources :subscribe_articles, only: %i[new create destroy], param: :uuid
  resources :subscribe_tags, only: %i[new create destroy]

  resources :tags, only: %i[index]

  resources :currencies, only: %i[index]
  resources :users, only: :show, param: :uid, as: :full_user do
    get :share
  end
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

  get '/:uid',
      to: 'users#show',
      constraints: {
        uid: /(\d+|[0-9a-fA-F]{8}-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{12}|0x[0-9a-zA-Z]{40})/
      },
      as: :user

  get '/:uid/:uuid',
      to: 'articles#show',
      constraints: {
        uid: /(\d+|[0-9a-fA-F]{8}-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{12}|0x[0-9a-zA-Z]{40})/,
        uuid: /[0-9a-fA-F]{8}-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{12}/
      },
      as: :user_article
end
