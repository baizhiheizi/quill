# frozen_string_literal: true

module Types
  class AnnouncementType < Types::BaseObject
    field :id, Int, null: false
    field :content, String, null: false
    field :message_type, String, null: false
    field :state, String, null: false
    field :delivered_at, GraphQL::Types::ISO8601DateTime, null: true
  end
end
