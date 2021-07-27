# frozen_string_literal: true

module Types
  class ArticleUpdateInputType < BaseInputObject
    argument :id, ID, required: true
    argument :title, String, required: false
    argument :intro, String, required: false
    argument :content, String, required: false
  end
end
