# frozen_string_literal: true

module Resolvers
  class MyReadingSubscriptionConnectionResolver < MyBaseResolver
    argument :after, String, required: false

    type Types::UserConnectionType, null: false

    def resolve(**)
      current_user.reading_subscribe_users
    end
  end
end
