# frozen_string_literal: true

module Mutations
  class AdminBanUserMutation < AdminBaseMutation
    argument :id, ID, required: true

    type Types::UserType

    def resolve(id:)
      user = User.find_by(id: id)
      user&.ban!
      user&.reload
    end
  end
end
