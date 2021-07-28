# frozen_string_literal: true

module Types
  class ArticleUpdateInputType < BaseInputObject
    argument :uuid, ID, required: true
    argument :title, String, required: false
    argument :intro, String, required: false
    argument :content, String, required: false
    argument :price, Float, required: false
    argument :tag_names, [String], required: false
  end
end
