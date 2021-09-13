# frozen_string_literal: true

module Resolvers
  class MySubscribingConnectionResolver < MyBaseResolver
    argument :after, String, required: false

    type Types::UserConnectionType, null: false

    def resolve(**)
      current_user.subscribe_users
    end
  end
end
