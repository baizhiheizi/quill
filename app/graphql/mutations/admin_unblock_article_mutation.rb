# frozen_string_literal: true

module Mutations
  class AdminUnblockArticleMutation < AdminBaseMutation
    argument :uuid, ID, required: true

    type Types::ArticleType

    def resolve(uuid:)
      article = Article.find_by(uuid: uuid)
      article&.unblock!
      article&.reload
    end
  end
end
