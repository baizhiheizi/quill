# frozen_string_literal: true

module Types
  class ArticlePublishInputType < BaseInputObject
    argument :uuid, ID, required: true
    argument :price, Float, required: true
    argument :asset_id, String, required: true
    argument :article_references, [Types::ArticleReferenceInputType], required: false
  end
end
