# frozen_string_literal: true

module Resolvers
  class BaseResolver < GraphQL::Schema::Resolver
    def current_user
      context[:current_user]
    end
  end
end
