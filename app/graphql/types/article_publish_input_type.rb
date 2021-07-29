# frozen_string_literal: true

module Types
  class ArticlePublishInputType < BaseInputObject
    argument :uuid, ID, required: true
    argument :price, Float, required: false
    argument :asset_id, String, required: false
    argument :article_references, [Types::ArticleReferenceInputType], required: false
  end
end
