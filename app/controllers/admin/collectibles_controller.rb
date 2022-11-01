# frozen_string_literal: true

module Admin
  class CollectiblesController < Admin::BaseController
    def index
      @state = params[:state] || 'all'
      @source = params[:source] || 'all'
      @order_by = params[:order_by] || 'updated_at_desc'

      collectibles = Collectible.includes(:collection, :source)

      collectibles = collectibles.where(collection_id: params[:collection_id]) if params[:collection_id].present?

      collectibles =
        case @state
        when 'all'
          collectibles
        else
          collectibles.where(state: @state)
        end

      collectibles =
        case @source
        when 'all'
          collectibles
        else
          collectibles.where(source_type: @source)
        end

      collectibles =
        case @order_by
        when 'updated_at_desc'
          collectibles.order(updated_at: :desc)
        when 'updated_at_asc'
          collectibles.order(updated_at: :asc)
        end

      @query = params[:query].to_s.strip
      collectibles =
        collectibles.ransack(
          {
            collectible_name_cont_any: @query,
            collectible_collection_id_eq: @query,
            token_id_eq: @query
          }.merge(m: 'or')
        ).result

      @pagy, @collectibles = pagy_countless collectibles
    end

    def show
      @collectible = Collectible.find_by metahash: params[:metahash]
    end
  end
end
