# frozen_string_literal: true

module Types
  class ArticleSnapshotType < BaseObject
    field :id, ID, null: false
    field :article_uuid, String, null: false
    field :file_hash, String, null: false
    field :tx_id, String, null: false
    field :signature_url, String, null: false

    field :article, Types::ArticleType, null: false

    def article
      BatchLoader::GraphQL.for(object.article_uuid).batch do |article_uuids, loader|
        Article.where(uuid: article_uuids).each { |article| loader.call(article.uuid, article) }
      end
    end
  end
end
