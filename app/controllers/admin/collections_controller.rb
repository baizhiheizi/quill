# frozen_string_literal: true

module Admin
  class CollectionsController < Admin::BaseController
    def index
      @state = params[:state] || "all"
      @order_by = params[:order_by] || "created_at_desc"

      collections = Collection.includes(:author, :currency)

      collections = collections.where(author_id: params[:user_id]) if params[:user_id].present?

      collections =
        case @state
        when "all"
          collections
        else
          collections.where(state: @state)
        end

      collections =
        case @order_by
        when "created_at_desc"
          collections.order(created_at: :desc)
        when "created_at_asc"
          collections.order(created_at: :asc)
        end

      @query = params[:query].to_s.strip
      collections =
        collections.ransack(
          {
            collection_name_cont_any: @query,
            collection_symbol_eq: @query,
            collection_uuid_eq: @query
          }.merge(m: "or")
        ).result

      @pagy, @collections = pagy(:countless, collections)
      @articles_count_by_collection_uuid = preload_articles_count_by_collection_uuid(@collections)
    end

    # Batched COUNT(*) preloader for the per-collection article counts
    # rendered in `app/views/admin/collections/_collection.html.erb` line 31
    # (`collection.articles.count`). Without this prime, each row fires an
    # independent `SELECT COUNT(*) FROM articles WHERE collection_id = $1`
    # — for the default pagy page of 50 collections that is 50 extra
    # SELECTs per request, just to render the badge number next to the
    # "Articles" admin link.
    #
    # `Collection#articles` uses `primary_key: :uuid`, so the foreign key
    # on `articles` is `collection_id` (a `uuid` column that stores the
    # Collection's UUID string, not its bigint id). The grouped-COUNT
    # below matches the in-Ruby `has_many` association exactly: a single
    # `SELECT collection_id, COUNT(*) FROM articles WHERE collection_id IN
    # (...) GROUP BY collection_id` produces a Hash{uuid => count}, which
    # the partial reads via `defined?(`@articles_count_by_collection_uuid`)`
    # so the partial stays correct in any other render context (show,
    # turbo_stream, future callers) that has not primed the ivar.
    def preload_articles_count_by_collection_uuid(collections)
      uuids = collections.map(&:uuid).compact
      return {} if uuids.empty?

      Article
        .where(collection_id: uuids)
        .group(:collection_id)
        .count
    end
    private :preload_articles_count_by_collection_uuid

    def show
      @collection = Collection.find params[:id]
      @tab = params[:tab] || "orders"
    end
  end
end
