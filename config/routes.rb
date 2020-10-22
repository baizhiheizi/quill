# frozen_string_literal: true

class AdminConstraint
  def matches?(request)
    return false if request.session[:current_admin_id].blank?

    admin = Administrator.find_by(id: request.session[:current_admin_id])
    admin.present?
  end
end

Rails.application.routes.draw do
  mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/graphql' if Rails.env.development?
  post '/graphql', to: 'graphql#execute'

  root to: 'home#index'

  namespace :admin do
    root to: 'dashboard#index'
  end

  get '*path' => 'home#index'
end
