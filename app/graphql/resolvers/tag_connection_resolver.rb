# frozen_string_literal: true

module Resolvers
  class TagConnectionResolver < BaseResolver
    argument :after, String, required: false

    type Types::TagConnectionType, null: false

    def resolve(**)
      Tag.all.order(articles_count: :desc, created_at: :desc)
    end
  end
end
