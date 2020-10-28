# frozen_string_literal: true

module Resolvers
  class MyBaseResolver < BaseResolver
    def self.authorized?(_object, context)
      super && context[:current_user].present?
    end
  end
end
