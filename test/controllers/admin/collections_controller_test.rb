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
end
