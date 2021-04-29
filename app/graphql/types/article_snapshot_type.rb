# frozen_string_literal: true

module Types
  class ArticleSnapshotType < BaseObject
    field :id, ID, null: false
    field :article_uuid, String, null: false
    field :file_hash, String, null: false
    field :tx_id, String, null: false
    field :signature_url, String, null: false

    def author
      BatchLoader::GraphQL.for(object.author_id).batch do |author_ids, loader|
        User.where(id: author_ids).each { |author| loader.call(author.id, author) }
      end
    end
  end
end
