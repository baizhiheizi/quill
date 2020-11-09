# frozen_string_literal: true

module Types
  class MixinMessageType < Types::BaseObject
    field :id, Int, null: false
    field :action, String, null: false
    field :category, String, null: false
    field :content, String, null: false
    field :user_id, String, null: true
    field :processed_at, GraphQL::Types::ISO8601DateTime, null: true

    field :user, Types::UserType, null: true

    def user
      BatchLoader::GraphQL.for(object.user_id).batch do |user_ids, loader|
        User.where(id: user_ids).each { |user| loader.call(user.id, user) }
      end
    end
  end
end
