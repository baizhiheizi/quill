# frozen_string_literal: true

module Admin
  class NonFungibleOutputsController < Admin::BaseController
    def index
      @state = params[:state] || 'unspent'
      @order_by = params[:order_by] || 'updated_at_desc'

      non_fungible_outputs = NonFungibleOutput.includes(:user, collectible: :nft_collection)

      non_fungible_outputs = non_fungible_outputs.where(user_id: params[:user_id]) if params[:user_id].present?

      non_fungible_outputs =
        case @state
        when 'all'
          non_fungible_outputs
        else
          non_fungible_outputs.where(state: @state)
        end

      non_fungible_outputs =
        case @order_by
        when 'updated_at_desc'
          non_fungible_outputs.order(updated_at: :desc)
        when 'updated_at_asc'
          non_fungible_outputs.order(updated_at: :asc)
        end

      @query = params[:query].to_s.strip
      non_fungible_outputs =
        non_fungible_outputs.ransack(
          {
            collectible_name_cont_any: @query,
            collectible_collection_id_eq: @query,
            user_id_eq: @query,
            token_id_eq: @query
          }.merge(m: 'or')
        ).result

      @pagy, @non_fungible_outputs = pagy_countless non_fungible_outputs
    end

    def show
      @non_fungible_output = NonFungibleOutput.find params[:id]
    end
  end
end
