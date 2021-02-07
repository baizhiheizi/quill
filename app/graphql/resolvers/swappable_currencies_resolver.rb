# frozen_string_literal: true

module Resolvers
  class SwappableCurrenciesResolver < BaseResolver
    type [Types::CurrencyType], null: false

    def resolve
      Currency.swappable
    end
  end
end
