# frozen_string_literal: true

module Admin
  class CollectionsController < Admin::BaseController
    def index
      @state = params[:state] || 'all'
      @order_by = params[:order_by] || 'created_at_desc'

      collections = Collection.includes(:author, :currency, :nft_collection)

      collections = collections.where(author_id: params[:user_id]) if params[:user_id].present?

      collections =
        case @state
        when 'all'
          collections
        else
          collections.where(state: @state)
        end

      collections =
        case @order_by
        when 'created_at_desc'
          collections.order(created_at: :desc)
        when 'created_at_asc'
          collections.order(created_at: :asc)
        end

      @query = params[:query].to_s.strip
      collections =
        collections.ransack(
          {
            collection_name_cont_any: @query,
            collection_symbol_eq: @query,
            collection_uuid_eq: @query
          }.merge(m: 'or')
        ).result

      @pagy, @collections = pagy_countless collections
    end

    def show
      @collection = Collection.find params[:id]
      @tab = params[:tab] || 'orders'
    end
  end
end
