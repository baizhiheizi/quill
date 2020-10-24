# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :create_article, mutation: Mutations::CreateArticleMutation
  end
end
