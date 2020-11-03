# frozen_string_literal: true

module Resolvers
  class AdminUserConnectionResolver < AdminBaseResolver
    argument :after, String, required: false

    type Types::UserConnectionType, null: false

    def resolve(params = {})
      User.all.order(created_at: :desc)
    end
  end
end
