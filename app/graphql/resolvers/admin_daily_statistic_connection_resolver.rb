# frozen_string_literal: true

module Resolvers
  class AdminDailyStatisticConnectionResolver < AdminBaseResolver
    argument :start_date, String, required: false
    argument :end_date, String, required: false
    argument :after, String, required: false

    type Types::DailyStatisticType.connection_type, null: false

    def resolve(**params)
      if params[:start_date].present? && params[:end_date].present?
        DailyStatistic.where(datetime: DateTime.parse(params[:start_date])...DateTime.parse(params[:end_date]))
      else
        DailyStatistic.all
      end
    end
  end
end
