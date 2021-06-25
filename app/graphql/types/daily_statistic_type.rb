# frozen_string_literal: true

module Types
  class DailyStatisticType < Types::BaseObject
    field :id, ID, null: false
    field :datetime, GraphQL::Types::ISO8601DateTime, null: false
    field :date, String, null: false
    field :new_users_count, Int, null: true
    field :paid_users_count, Int, null: true
    field :new_payments_count, Int, null: true
    field :new_payers_count, Int, null: true
    field :new_articles_count, Int, null: true

    def date
      object.datetime.strftime('%Y-%m-%d')
    end
  end
end
