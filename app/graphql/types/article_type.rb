# frozen_string_literal: true

module Types
  class ArticleType < BaseObject
    field :uuid, ID, null: false
    field :id, Integer, null: false
    field :title, String, null: false
    field :intro, String, null: false
    field :content, String, null: true
    field :asset_id, String, null: false
    field :price, Float, null: false
    field :revenue, Float, null: false
    field :orders_count, Integer, null: false
    field :comments_count, Integer, null: false
    field :authorized, Boolean, null: true

    field :author, Types::UserType, null: false
    field :readers, Types::UserConnectionType, null: false
    field :comments, Types::CommentConnectionType, null: false

    def content
      return unless object.authorized?(context[:current_user])

      object.content
    end

    def authorized
      object.authorized?(context[:current_user])
    end
  end
end
