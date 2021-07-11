# frozen_string_literal: true

module Types
  class ArticleReferenceInputType < BaseInputObject
    argument :reference_id, ID, required: true
    argument :revenue_ratio, Float, required: true
  end
end
