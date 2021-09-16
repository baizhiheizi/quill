# frozen_string_literal: true

module Resolvers
  class UserSubscriberConnectionResolver < MyBaseResolver
    argument :uid, ID, required: true
    argument :after, String, required: false

    type Types::UserConnectionType, null: false

    def resolve(params)
      user = User.find_by uid: params[:uid]
      user.subscribe_by_users
    end
  end
end
