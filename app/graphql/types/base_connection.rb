# frozen_string_literal: true

module Types
  class BaseConnection < GraphQL::Types::Relay::BaseConnection
    field :total_count, Integer, 'Total # of objects returned from this Plural Query', null: false

    def total_count
      object&.items&.count
    end
  end
end
