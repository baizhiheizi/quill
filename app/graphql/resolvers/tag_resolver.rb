# frozen_string_literal: true

module Resolvers
  class TagResolver < BaseResolver
    argument :id, ID, required: true

    type Types::TagType, null: true

    def resolve(id:)
      Tag.find_by(id: id)
    end
  end
end
