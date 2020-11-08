# frozen_string_literal: true

module Types
  class CommentType < BaseObject
    field :id, Int, null: false
    field :content, String, null: true
    field :deleted_at, GraphQL::Types::ISO8601DateTime, null: true

    field :author, Types::UserType, null: true
    field :commentable, Types::ArticleType, null: false

    def content
      return if object.deleted? && context[:session][:current_admin_id].blank?

      object.content
    end

    def author
      BatchLoader::GraphQL.for(object.author_id).batch do |author_ids, loader|
        User.where(id: author_ids).each { |author| loader.call(author.id, author) }
      end
    end
  end
end
