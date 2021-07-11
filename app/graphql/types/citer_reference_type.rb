# frozen_string_literal: true

module Types
  class CiterReferenceType < Types::BaseObject
    field :id, ID, null: false
    field :revenue_ratio, Float, null: false

    field :citer, Types::ArticleType, null: false
    field :reference, Types::ArticleType, null: false

    def citer
      BatchLoader::GraphQL.for(object.citer_id).batch do |citer_ids, loader|
        Article.where(id: citer_ids).each { |citer| loader.call(citer.id, citer) }
      end
    end

    def reference
      BatchLoader::GraphQL.for(object.reference_id).batch do |reference_ids, loader|
        Article.where(id: reference_ids).each { |reference| loader.call(reference.id, reference) }
      end
    end
  end
end
