# frozen_string_literal: true

module Admin
  class MixinNetworkUsersController < Admin::BaseController
    def index
      mixin_network_users = MixinNetworkUser.all
      mixin_network_users = mixin_network_users.where(owner_type: params[:owner_type], owner_id: params[:owner_type]) if params[:owner_id].present? && params[:owner_type].present?

      @state = params[:state] || 'all'
      mixin_network_users =
        case @state
        when 'ready'
          mixin_network_users.ready
        when 'unready'
          mixin_network_users.unready
        else
          mixin_network_users
        end

      @owner_type = params[:owner_type] || 'all'
      mixin_network_users =
        case @owner_type
        when 'Article'
          mixin_network_users.where(owner_type: 'Article')
        when 'User'
          mixin_network_users.where(owner_type: 'User')
        else
          mixin_network_users
        end

      @order_by = params[:order_by] || 'created_at_desc'
      mixin_network_users =
        case @order_by
        when 'created_at_desc'
          mixin_network_users.order(created_at: :desc)
        when 'created_at_asc'
          mixin_network_users.order(created_at: :asc)
        end

      @query = params[:query].to_s.strip
      mixin_network_users =
        mixin_network_users.ransack(
          {
            id_eq: @query,
            uuid_eq: @query,
            session_id_eq: @query
          }.merge(m: 'or')
        ).result

      @pagy, @mixin_network_users = pagy_countless mixin_network_users
    end

    def show
      @tab = params[:tab] || 'assets'
      @mixin_network_user = MixinNetworkUser.find params[:id]
    end
  end
end
