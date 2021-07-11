# frozen_string_literal: true

module Types
  class ArticleInputType < BaseInputObject
    argument :title, String, required: true
    argument :intro, String, required: true
    argument :content, String, required: true
    argument :price, Float, required: true
    argument :state, String, required: true
    argument :asset_id, String, required: true
    argument :tag_names, [String], required: false
    argument :article_references, [Types::ArticleReferenceInputType], required: false
  end
end
