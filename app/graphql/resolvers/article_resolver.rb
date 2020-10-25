# frozen_string_literal: true

module Resolvers
  class ArticleResolver < BaseResolver
    argument :uuid, ID, required: true

    type Types::ArticleType, null: true

    def resolve(uuid:)
      Article.find_by(uuid: uuid)
    end
  end
end
