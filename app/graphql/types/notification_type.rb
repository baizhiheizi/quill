# frozen_string_literal: true

module Types
  class NotificationType < Types::BaseObject
    field :id, ID, null: false
    field :read_at, GraphQL::Types::ISO8601DateTime, null: true
    field :type, String, null: false
    field :message, String, null: true
    field :url, String, null: true

    field :recipient, Types::UserType, null: false

    def recipient
      BatchLoader::GraphQL.for(object.recipient_id).batch do |user_ids, loader|
        User.where(id: user_ids).each { |user| loader.call(user.id, user) }
      end
    end
  end
end
