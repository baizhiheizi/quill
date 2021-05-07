# frozen_string_literal: true

module Mutations
  class AdminSignArticleSnapshotMutation < AdminBaseMutation
    argument :id, ID, required: true

    type Types::ArticleSnapshotType

    def resolve(id:)
      snapshot = ArticleSnapshot.find(id)
      snapshot.sign_on_chain!

      snapshot.reload
    end
  end
end
