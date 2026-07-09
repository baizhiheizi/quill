# frozen_string_literal: true

module Admin
  class MixinNetworkSnapshotsController < Admin::BaseController
    def index
      mixin_network_snapshots = MixinNetworkSnapshot.all
      mixin_network_snapshots = mixin_network_snapshots.where(user_id: params[:user_id]) if params[:user_id].present?
      mixin_network_snapshots = mixin_network_snapshots.where(opponent_id: params[:opponent_id]) if params[:opponent_id].present?

      @state = params[:state] || "all"
      mixin_network_snapshots =
        case @state
        when "unprocessed"
          mixin_network_snapshots.unprocessed
        when "processed"
          mixin_network_snapshots.processed
        when "mtg"
          mixin_network_snapshots.where(opponent_id: nil)
        else
          mixin_network_snapshots
        end

      @opponent = params[:opponent] || "all"
      mixin_network_snapshots =
        case @opponent
        when "quill"
          mixin_network_snapshots.where(opponent_id: QuillBot.api.client_id)
        when "mtg"
          mixin_network_snapshots.where(opponent_id: nil)
        else
          mixin_network_snapshots
        end

      @direction = params[:direction] || "all"
      mixin_network_snapshots =
        case @direction
        when "input"
          mixin_network_snapshots.where(amount: 0...)
        when "output"
          mixin_network_snapshots.where(amount: ...0)
        else
          mixin_network_snapshots
        end

      @order_by = params[:order_by] || "created_at_desc"
      mixin_network_snapshots =
        case @order_by
        when "processed_at_desc"
          mixin_network_snapshots.order(processed_at: :desc)
        when "created_at_desc"
          mixin_network_snapshots.order(created_at: :desc)
        when "created_at_asc"
          mixin_network_snapshots.order(created_at: :asc)
        end

      @query = params[:query].to_s.strip
      mixin_network_snapshots =
        mixin_network_snapshots.ransack(
          {
            id_eq: @query,
            user_id_eq: @query,
            opponent_id_eq: @query,
            trace_id_eq: @query,
            asset_id_eq: @query
          }.merge(m: "or")
        ).result

      # Close per-row N+1s walked by `admin/mixin_network_snapshots/_mixin_network_snapshot.html.erb`.
      # Without this, a 50-row admin page fires ~200 SELECTs for the four
      # belongs_to + ~250 more for the opponent avatar chain. With the
      # prime the page renders in ~7 SELECTs regardless of page size.
      @pagy, @mixin_network_snapshots = pagy(:countless, mixin_network_snapshots.includes(*index_includes))
    end

    def show
      # Same partial chain as `index` — preload the belongs_to + the opponent
      # avatar chain so the show view renders flat (1 SELECT for each chain).
      @mixin_network_snapshot = MixinNetworkSnapshot.includes(*index_includes).find(params[:id])
    end

    def process_now
      @mixin_network_snapshot = MixinNetworkSnapshot.find params[:mixin_network_snapshot_id]
      @mixin_network_snapshot.process!
    end

    private

    # Eager-load chain shared between `index` and `show`. See
    # `admin/mixin_network_snapshots/_mixin_network_snapshot.html.erb`
    # for the exact fields walked per row.
    def index_includes
      [ :wallet, :opponent_wallet, :currency, { opponent: admin_user_field_preloads } ]
    end
  end
end
