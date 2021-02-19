# frozen_string_literal: true

module Mutations
  class CreateAccessTokenMutation < Mutations::BaseMutation
    argument :memo, String, required: true

    type Types::AccessTokenType

    def resolve(memo:)
      current_user.access_tokens.create!(memo: memo)
    end
  end
end
