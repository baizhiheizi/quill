# frozen_string_literal: true

module Resolvers
  class AdminUserResolver < AdminBaseResolver
    argument :uid, ID, required: true

    type Types::UserType, null: true

    def resolve(uid:)
      User.find_by uid: uid
    end
  end
end
