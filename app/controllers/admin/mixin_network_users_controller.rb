# frozen_string_literal: true

module Admin
  class MixinNetworkUsersController < Admin::BaseController
    def index
      mixin_network_users = MixinNetworkUser.all
      mixin_network_users = mixin_network_users.where(owner_type: params[:owner_type], owner_id: params[:owner_id]) if params[:owner_id].present? && params[:owner_type].present?

      @type = params[:type] || "Splitter"
      mixin_network_users =
        case @type
        when "all"
          mixin_network_users
        else
          mixin_network_users.where(type: @type)
        end

      @state = params[:state] || "all"
      mixin_network_users =
        case @state
        when "ready"
          mixin_network_users.ready
        when "unready"
          mixin_network_users.unready
        else
          mixin_network_users
        end

      @owner_type = params[:owner_type] || "all"
      mixin_network_users =
        case @owner_type
        when "Article"
          mixin_network_users.where(owner_type: "Article")
        when "User"
          mixin_network_users.where(owner_type: "User")
        else
          mixin_network_users
        end

      @order_by = params[:order_by] || "created_at_desc"
      mixin_network_users =
        case @order_by
        when "created_at_desc"
          mixin_network_users.order(created_at: :desc)
        when "created_at_asc"
          mixin_network_users.order(created_at: :asc)
        end

      @query = params[:query].to_s.strip
      mixin_network_users =
        mixin_network_users.ransack(
          {
            id_eq: @query,
            uuid_eq: @query,
            session_id_eq: @query
          }.merge(m: "or")
        ).result

      # Eager-load associations consumed by the rendered partial
      # `app/views/admin/mixin_network_users/_mixin_network_user.html.erb`:
      #   - `:owner` → `mixin_network_user.owner` (polymorphic Article/User).
      #     Rails 7+ groups preloaded polymorphic rows by `owner_type` and
      #     fires one SELECT per type instead of one per row.
      #     The partial dispatches on `mixin_network_user.owner.is_a? Article|User`
      #     and renders the corresponding field partial.
      #   - `owner: admin_user_field_preloads` → for User-owner rows the partial
      #     renders `admin/users/_field` → `shared/_avatar`, which walks
      #     `user.avatar_image_thumb` → `authorization.raw["avatar_url"]` +
      #     `avatar_attachment.blob.variant_records`. The preload chain primes
      #     all of those in IN-batched SELECTs. Article-owner rows ignore the
      #     user-shaped keys (Rails 7+ polymorphic preload only follows keys
      #     present on each target model), so no extra SELECTs fire on that branch.
      #
      # Without the User-owner preload chain each User-owner row triggers
      # ~4-5 SELECTs (authorization + attachment + blob + variant_records).
      # For an admin viewing a pagy page of 50 User-owner Mixin Network Users,
      # the action would run ~200-250 extra SELECTs per request.
      @pagy, @mixin_network_users = pagy(:countless, mixin_network_users.includes(*index_includes))
    end

    def show
      @tab = params[:tab] || "assets"
      @mixin_network_user = MixinNetworkUser.find params[:id]
    end

    private

    # Eager-load chain shared between `index` and (potentially) `show`.
    # See `admin/mixin_network_users/_mixin_network_user.html.erb` for the
    # exact fields walked per row.
    def index_includes
      [ { owner: admin_user_field_preloads } ]
    end
  end
end
