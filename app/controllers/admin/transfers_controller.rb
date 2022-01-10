# frozen_string_literal: true

module Admin
  class TransfersController < Admin::BaseController
    def index
      transfers = Transfer.all
      transfers = transfers.where(opponent_id: params[:opponent_id]) if params[:opponent_id].present?

      @state = params[:state] || 'all'
      transfers =
        case @state
        when 'unprocessed'
          transfers.unprocessed
        when 'processed'
          transfers.processed
        else
          transfers
        end

      @transfer_type = params[:transfer_type] || 'all'
      transfers =
        case @transfer_type
        when 'all'
          transfers
        else
          transfers.where(transfer_type: @transfer_type)
        end

      @order_by = params[:order_by] || 'created_at_desc'
      transfers =
        case @order_by
        when 'processed_at_desc'
          transfers.order(processed_at: :desc)
        when 'created_at_desc'
          transfers.order(created_at: :desc)
        when 'created_at_asc'
          transfers.order(created_at: :asc)
        end

      @query = params[:query].to_s.strip
      transfers =
        transfers.ransack(
          {
            id_eq: @query,
            wallet_id_eq: @query,
            trace_id_eq: @query,
            asset_id_eq: @query
          }.merge(m: 'or')
        ).result

      @pagy, @transfers = pagy_countless transfers
    end

    def show
      @transfer = Transfer.find params[:id]
    end
  end
end
