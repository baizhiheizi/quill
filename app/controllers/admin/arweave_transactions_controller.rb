# frozen_string_literal: true

module Admin
  class ArweaveTransactionsController < Admin::BaseController
    def index
      arweave_transactions = ArweaveTransaction.all
      arweave_transactions = arweave_transactions.where(owner_id: params[:owner_id]) if params[:owner_id].present?
      arweave_transactions = arweave_transactions.where(article_uuid: params[:article_uuid]) if params[:article_uuid].present?

      @state = params[:state] || 'all'
      arweave_transactions =
        case @state
        when 'all'
          arweave_transactions
        else
          arweave_transactions.where(state: @state)
        end

      @order_by = params[:order_by] || 'created_at_desc'
      arweave_transactions =
        case @order_by
        when 'created_at_desc'
          arweave_transactions.order(created_at: :desc)
        when 'created_at_asc'
          arweave_transactions.unscope(:order).order(created_at: :asc)
        end

      @query = params[:query].to_s.strip
      arweave_transactions =
        arweave_transactions.ransack(
          {
            id_eq: @query,
            owner_id_eq: @query,
            tx_id_eq: @query,
            digest_eq: @query,
            asset_uuid_eq: @query
          }.merge(m: 'or')
        ).result

      @pagy, @arweave_transactions = pagy_countless arweave_transactions
    end

    def show
      @arweave_transaction = ArweaveTransaction.find params[:id]
    end
  end
end
