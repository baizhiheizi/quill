# frozen_string_literal: true

module Mutations
  class AdminSignArticleSnapshotMutation < AdminBaseMutation
    argument :id, ID, required: true

    type Types::ArticleSnapshotType

    def resolve(id:)
      ArticleSnapshot.find(id).request_sign
    end
  end
end
