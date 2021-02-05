# frozen_string_literal: true

module Resolvers
  class PricableCurrenciesResolver < BaseResolver
    type [Types::CurrencyType], null: false

    def resolve
      Currency.pricable
    end
  end
end
