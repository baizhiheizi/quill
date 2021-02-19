# frozen_string_literal: true

module Mutations
  class DeleteAccessTokenMutation < Mutations::BaseMutation
    argument :id, ID, required: true

    type Boolean

    def resolve(id:)
      current_user.access_tokens.find(id).soft_delete!
    end
  end
end
