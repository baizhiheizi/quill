# frozen_string_literal: true

module Types
  class ArticleInputType < BaseInputObject
    argument :id, ID, required: false
    argument :title, String, required: false
    argument :intro, String, required: false
    argument :content, String, required: false
    argument :price, Float, required: false
    argument :state, String, required: false
    argument :asset_id, String, required: false
    argument :tag_names, [String], required: false
    argument :article_references, [Types::ArticleReferenceInputType], required: false
  end
end
