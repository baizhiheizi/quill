# frozen_string_literal: true

module Admin
  class StatisticsController < Admin::BaseController
    def index
      statistics = Statistic.all

      # The query form submits `:state`; filter on the STI type column.
      @state = params[:state] || "all"
      statistics =
        case @state
        when "all"
          statistics
        else
          statistics.where(type: @state)
        end

      @order_by = allowed_param(:order_by, "datetime_desc", %w[datetime_desc datetime_asc])
      statistics =
        case @order_by
        when "datetime_desc"
          statistics.order(datetime: :desc)
        when "datetime_asc"
          statistics.order(datetime: :asc)
        end

      @pagy, @statistics = pagy(:countless, statistics)
    end
  end
end
