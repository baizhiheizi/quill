# frozen_string_literal: true

module Types
  class UserAccessTokenType < BaseObject
    field :id, ID, null: false
    field :value, String, null: false
    field :desensitized_value, String, null: false
    field :memo, String, null: false

    field :user, Types::UserType, null: false
  end
end
