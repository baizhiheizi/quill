# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :create_article, mutation: Mutations::CreateArticleMutation
    field :create_comment, mutation: Mutations::CreateCommentMutation
  end
end
