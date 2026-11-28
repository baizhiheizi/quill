# frozen_string_literal: true

require "test_helper"

class Admin::CollectionsControllerTest < ActionController::TestCase
  tests Admin::CollectionsController

  setup do
    @admin = administrators(:one)
    # `Admin::BaseController#authenticate_admin!` only checks
    # `current_admin.blank?`. We bypass it by setting the session directly.
    @request.session[:current_admin_id] = @admin.id
  end

  # Admin collections index N+1 regression guard.
  #
  # `Admin::CollectionsController#index` renders
  # `app/views/admin/collections/_collection.html.erb` which calls
  # `collection.articles.count` to render the badge next to the
  # "Articles" admin link. Without the prime, that fires one
  # `SELECT COUNT(*) FROM articles WHERE collection_id = $1` per row,
  # so a pagy page of 50 collections costs 50 extra SELECTs per request.
  #
  # This test pins the batched behaviour: regardless of how many collections
  # the page returns, the preloader must emit exactly one GROUP BY query
  # and the partial must read from that prime (no per-row COUNT(*) calls).

  test "preload_articles_count_by_collection_uuid is a no-op on empty input" do
    assert_equal({}, @controller.send(:preload_articles_count_by_collection_uuid, []))
  end

  test "preload_articles_count_by_collection_uuid emits exactly one batched GROUP BY COUNT query regardless of input size" do
    # Ensure fixture collections have UUIDs to key off (the default fixture
    # rows leave `uuid: nil` because the admin index doesn't pre-create them).
    if collections(:one).uuid.blank?
      collections(:one).update_column(:uuid, SecureRandom.uuid)
    end
    if collections(:two).uuid.blank?
      collections(:two).update_column(:uuid, SecureRandom.uuid)
    end

    # Insert deterministic rows so the grouped count has something to count.
    # `articles.content` lives on `article_references`, not on `articles`
    # directly — only the AR-side columns go into `insert_all!`.
    article = articles(:published_free)
    now = Time.current
    Article.insert_all!([
      {
        author_id: article.author_id,
        asset_id: article.asset_id,
        price: 1.0,
        intro: "alpha",
        title: "alpha",
        uuid: SecureRandom.uuid,
        collection_id: collections(:one).uuid,
        state: "drafted",
        locale: "en",
        published_at: nil,
        created_at: now,
        updated_at: now
      },
      {
        author_id: article.author_id,
        asset_id: article.asset_id,
        price: 1.0,
        intro: "beta",
        title: "beta",
        uuid: SecureRandom.uuid,
        collection_id: collections(:one).uuid,
        state: "drafted",
        locale: "en",
        published_at: nil,
        created_at: now,
        updated_at: now
      },
      {
        author_id: article.author_id,
        asset_id: article.asset_id,
        price: 1.0,
        intro: "gamma",
        title: "gamma",
        uuid: SecureRandom.uuid,
        collection_id: collections(:two).uuid,
        state: "drafted",
        locale: "en",
        published_at: nil,
        created_at: now,
        updated_at: now
      }
    ])

    collections = Collection.where.not(uuid: nil).to_a

    # Capture every ActiveRecord SQL query emitted while running the
    # preloader. The preloader should emit exactly ONE query (the grouped
    # COUNT), not N per-collection COUNT(*) queries.
    queries = []
    callback = ->(_name, _start, _finish, _id, payload) do
      next if payload[:name] == "SCHEMA"

      queries << payload[:sql]
    end

    counts = nil
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      counts = @controller.send(:preload_articles_count_by_collection_uuid, collections)
    end

    article_count_queries = queries.count do |q|
      q =~ /FROM\s+"articles"/i
    end

    assert_equal 1, article_count_queries,
      "expected exactly 1 batched COUNT query on articles, got #{article_count_queries}:\n#{queries.join("\n")}"

    # The grouped COUNT hash maps `collection_id` (the UUID string) → count.
    assert_equal 2, counts[collections(:one).uuid]
    assert_equal 1, counts[collections(:two).uuid]
  end

  # Admin collections index avatar-chain N+1 regression guard.
  #
  # Every row renders `admin/users/field`, which draws the author's avatar
  # through `shared/_avatar` — that walks the attachment / blob /
  # authorization chain, so a row cost ~5 SELECTs. The index now carries
  # `User::AVATAR_PRELOADS` for `collection.author`, which resolves the
  # whole page in one query instead of one per row.
  #
  # The author rows themselves were already preloaded (`includes(:author)`),
  # so the `users` table was never the fan-out — the avatar chain was. The
  # assertion is therefore that the chain costs the same for a page of two
  # and a page of four: one preload, whatever the row count.
  test "index resolves every row's avatar in a fixed number of queries" do
    build_renderable_collection(collections(:one), users(:author), "Fixture One")
    build_renderable_collection(collections(:two), users(:author_zh), "Fixture Two")

    queries_two = capture_sql { get :index }

    assert_response :success
    assert_equal 2, @controller.instance_variable_get(:@collections).size

    build_renderable_collection(nil, users(:author_ja), "Live One")
    build_renderable_collection(nil, users(:reader_two), "Live Two")

    queries_four = capture_sql { get :index }

    assert_response :success
    assert_equal 4, @controller.instance_variable_get(:@collections).size

    assert_equal avatar_chain_query_count(queries_two), avatar_chain_query_count(queries_four),
      "expected the avatar chain to cost the same for two and four rows:\n" \
      "two rows:\n#{queries_two.join("\n")}\nfour rows:\n#{queries_four.join("\n")}"
  end

  test "index can sort by the updated_at column it displays" do
    # The collections list renders `collection.updated_at` in its last
    # column, but the sort options only covered `created_at` — picking a
    # sort ordered the rows by a timestamp the admin could not see, and the
    # options were labelled just "DESC"/"ASC" so it was not obvious which
    # one was being sorted.
    collections(:one).update_column(:updated_at, 2.days.ago)
    collections(:two).update_column(:updated_at, 1.hour.ago)

    @controller.params = ActionController::Parameters.new(order_by: "updated_at_desc")
    @controller.send(:index)

    ids = @controller.instance_variable_get(:@collections).map(&:id)
    assert_equal collections(:two).id, ids.first, "expected the most recently updated collection first"

    @controller.params = ActionController::Parameters.new(order_by: "updated_at_asc")
    @controller.send(:index)

    ids = @controller.instance_variable_get(:@collections).map(&:id)
    assert_equal collections(:one).id, ids.first, "expected the least recently updated collection first"
  end

  private

  # The collection fixtures carry no author, price, currency or uuid, and the
  # index row renders `collection.author` and `collection.price_tag` — so a
  # renderable row needs all of them. `collection` is nil for a row that
  # should be created rather than patched.
  def build_renderable_collection(collection, author, name)
    attributes = {
      name: name,
      symbol: name.gsub(/\s+/, ""),
      description: "A renderable collection.",
      asset_id: Currency::BTC_ASSET_ID,
      price: 10.0,
      revenue_ratio: 0.2,
      author_id: author.mixin_uuid,
      uuid: SecureRandom.uuid
    }

    if collection
      collection.update_columns(attributes)
      collection
    else
      Collection.create!(attributes)
    end
  end
end
