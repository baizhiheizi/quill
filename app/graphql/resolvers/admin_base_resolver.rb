# frozen_string_literal: true

module Resolvers
  class AdminBaseResolver < BaseResolver
    def self.authorized?(_object, context)
      super && context[:session][:current_admin_id].present?
    end
  end
end
