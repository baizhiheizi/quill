# frozen_string_literal: true

module Types
  class CommentType < BaseObject
    field :id, ID, null: false
    field :content, String, null: true
    field :deleted_at, GraphQL::Types::ISO8601DateTime, null: true
    field :upvotes_count, Int, null: false
    field :downvotes_count, Int, null: false
    field :upvoted, Boolean, null: true
    field :downvoted, Boolean, null: true

    field :author, Types::UserType, null: true
    field :commentable, Types::ArticleType, null: false

    def content
      return if object.deleted? && context[:session][:current_admin_id].blank?

      object.content
    end

    def upvoted
      return unless context[:current_user]

      BatchLoader::GraphQL.for(object.id).batch do |ids, loader|
        context[:current_user].upvote_comments.where(id: ids).each { |upvote_comment| loader.call(upvote_comment.id, upvote_comment.present?) }
      end
    end

    def downvoted
      return unless context[:current_user]

      BatchLoader::GraphQL.for(object.id).batch do |ids, loader|
        context[:current_user].downvote_comments.where(id: ids).each { |downvote_comment| loader.call(downvote_comment.id, downvote_comment.present?) }
      end
    end

    def author
      BatchLoader::GraphQL.for(object.author_id).batch do |author_ids, loader|
        User.where(id: author_ids).each { |author| loader.call(author.id, author) }
      end
    end
  end
end
