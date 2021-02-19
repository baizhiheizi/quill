# frozen_string_literal: true

module Types
  class AccessTokenType < BaseObject
    field :id, ID, null: false
    field :value, String, null: false
    field :desensitized_value, String, null: false
    field :memo, String, null: false
    field :last_request_ip, String, null: true
    field :last_request_url, String, null: true
    field :last_request_method, String, null: true
    field :last_request_at, GraphQL::Types::ISO8601DateTime, null: true

    field :user, Types::UserType, null: false
  end
end
