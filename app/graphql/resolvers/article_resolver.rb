# frozen_string_literal: true

module Resolvers
  class ArticleResolver < BaseResolver
    argument :uuid, ID, required: true

    type Types::ArticleType, null: true

    def resolve(uuid:)
      article = Article.find_by(uuid: uuid)
      return if article.blank?
      return unless article.published? || article.authorized?(current_user)

      article
    end
  end
end
