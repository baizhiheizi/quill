# frozen_string_literal: true

module Admin
  class BonusesController < Admin::BaseController
    def index
      bonuses = Bonus.all

      bonuses = bonuses.where(user_id: params[:user_id]) if params[:user_id].present?

      @state = params[:state] || 'all'
      bonuses =
        case @state
        when 'all'
          bonuses
        else
          bonuses.where(state: @state)
        end

      @order_by = params[:order_by] || 'created_at_desc'
      bonuses =
        case @order_by
        when 'created_at_desc'
          bonuses.order(created_at: :desc)
        when 'created_at_asc'
          bonuses.order(created_at: :asc)
        end

      @query = params[:query].to_s.strip
      bonuses =
        bonuses.ransack(
          {
            title_cont_any: @query,
            description_cont_all: @query,
            trace_id_eq: @query,
            asset_id_eq: @query
          }.merge(m: 'or')
        ).result

      @pagy, @bonuses = pagy_countless bonuses
    end

    def create
      @bonus = Bonus.create bonus_params
    end

    def deliver
      @bonus = Bonus.find_by id: params[:bonus_id]
      @bonus.deliver! if @bonus&.may_deliver?
      redirect_to admin_bonuses_path
    end

    private

    def bonus_params
      params.require(:bonus).permit(:asset_id, :amount, :user_id, :title, :description)
    end
  end
end
