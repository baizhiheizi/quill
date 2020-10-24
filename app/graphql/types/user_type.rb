# frozen_string_literal: true

module Types
  class UserType < Types::BaseObject
    field :id, Int, null: false
    field :name, String, null: false
    field :mixin_id, String, null: false
    field :mixin_uuid, String, null: false
    field :avatar_url, String, null: false
  end
end
