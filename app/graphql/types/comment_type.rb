# frozen_string_literal: true

module Types
  class CommentType < BaseObject
    field :id, Int, null: false
    field :content, String, null: true
    field :deleted_at, GraphQL::Types::ISO8601DateTime, null: true

    field :author, Types::UserType, null: true
    field :commentable, Types::ArticleType, null: false

    def content
      return if object.deleted?

      object.content
    end
  end
end
