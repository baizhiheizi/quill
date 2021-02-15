# frozen_string_literal: true

module Resolvers
  class TagConnectionResolver < BaseResolver
    argument :after, String, required: false

    type Types::TagConnectionType, null: false

    def resolve(**)
      Tag.all.order(updated_at: :desc, articles_count: :desc)
    end
  end
end
