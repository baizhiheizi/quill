# frozen_string_literal: true

module Resolvers
  class MyAccessTokenConnectionResolver < MyBaseResolver
    argument :after, String, required: false

    type Types::AccessTokenConnectionType, null: false

    def resolve(**_params)
      current_user.access_tokens.order(created_at: :desc)
    end
  end
end
