# frozen_string_literal: true

module Admin
  class StatisticsController < Admin::BaseController
    def index
      statistics = Statistic.all

      @type = params[:type] || 'all'
      statistics =
        case @type
        when 'all'
          statistics
        else
          statistics.where(type: @type)
        end

      @order_by = params[:order_by] || 'datetime_desc'
      statistics =
        case @order_by
        when 'datetime_desc'
          statistics.order(datetime: :desc)
        when 'datetime_asc'
          statistics.order(datetime: :asc)
        end

      @query = params[:query].to_s.strip
      statistics =
        statistics.ransack(
          {
            title_i_cont_all: @query,
            intro_i_cont_all: @query,
            content_i_cont_all: @query,
            uuid_eq: @query,
            id_eq: @query
          }.merge(m: 'or')
        ).result

      @pagy, @statistics = pagy_countless statistics
    end
  end
end
