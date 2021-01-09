# frozen_string_literal: true

module Resolvers
  class AdminUserResolver < AdminBaseResolver
    argument :mixin_id, ID, required: true

    type Types::UserType, null: true

    def resolve(mixin_id:)
      User.find_by mixin_id: mixin_id
    end
  end
end
