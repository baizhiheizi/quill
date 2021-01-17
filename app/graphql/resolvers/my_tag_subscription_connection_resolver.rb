# frozen_string_literal: true

module Resolvers
  class MyTagSubscriptionConnectionResolver < MyBaseResolver
    argument :after, String, required: false

    type Types::TagConnectionType, null: false

    def resolve(**)
      current_user.subscribe_tags
    end
  end
end
