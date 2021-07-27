# frozen_string_literal: true

module Mutations
  class CreateArticleMutation < Mutations::BaseMutation
    type Types::ArticleType

    def resolve(**params)
      current_user.articles.create!
    end
  end
end
