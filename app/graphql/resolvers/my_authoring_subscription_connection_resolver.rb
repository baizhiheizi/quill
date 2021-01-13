# frozen_string_literal: true

module Resolvers
  class MyAuthoringSubscriptionConnectionResolver < MyBaseResolver
    argument :after, String, required: false

    type Types::UserConnectionType, null: false

    def resolve(**)
      current_user.authoring_subscribe_users
    end
  end
end
