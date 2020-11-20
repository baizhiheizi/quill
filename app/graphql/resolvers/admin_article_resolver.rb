# frozen_string_literal: true

module Resolvers
  class AdminArticleResolver < AdminBaseResolver
    argument :uuid, ID, required: true

    type Types::ArticleType, null: false

    def resolve(uuid:)
      Article.find_by(uuid: uuid)
    end
  end
end
