# frozen_string_literal: true

class SubdomainConstraint
  def matches?(request)
    request.subdomain.present? && request.subdomain != 'www'
  end
end

constraints SubdomainConstraint.new do
  namespace :users, path: '/', as: :sub do
    root to: 'home#index'
    resources :articles, only: %i[index show]
  end
end
