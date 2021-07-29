# frozen_string_literal: true

module Mutations
  class DeleteArticleMutation < Mutations::BaseMutation
    argument :uuid, ID, required: true

    type Boolean

    def resolve(**params)
      current_user.articles.only_drafted.find_by(uuid: params[:uuid])&.destroy!
    end
  end
end
