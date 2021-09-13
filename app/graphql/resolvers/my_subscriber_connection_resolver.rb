# frozen_string_literal: true

module Resolvers
  class MySubscriberConnectionResolver < MyBaseResolver
    argument :after, String, required: false

    type Types::UserConnectionType, null: false

    def resolve(**)
      current_user.subscribe_by_users
    end
  end
end
