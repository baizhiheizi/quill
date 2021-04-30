# frozen_string_literal: true

module Resolvers
  class AdminArticleSnapshotConnectionResolver < AdminBaseResolver
    argument :article_uuid, String, required: false
    argument :after, String, required: false

    type Types::ArticleSnapshotType.connection_type, null: false

    def resolve(**params)
      if params[:article_uuid].present?
        Article.find_by(uuid: params[:article_uuid]).snapshots.order(created_at: :desc)
      else
        ArticleSnapshot.all.order(created_at: :desc)
      end
    end
  end
end
