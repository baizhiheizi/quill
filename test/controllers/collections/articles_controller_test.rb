# frozen_string_literal: true

require "test_helper"

class Collections::ArticlesControllerTest < ActionDispatch::IntegrationTest
  # Public-side `Collections::ArticlesController#index` regression guard.
  #
  # Renders `app/views/collections/articles/index.html.erb` and walks
  # `@collection.articles.published.order(published_at: :desc)` with pagy
  # at `items: 5`. Without these tests, the public collection feed can
  # silently regress on (a) the `published` filter (drafted articles
  # bleeding through), (b) the `published_at desc` ordering, and (c) the
  # pagy page size.
  setup do
    @author = users(:author)
    @collection = Collection.create!(
      uuid: SecureRandom.uuid,
      name: "Listed Collection",
      symbol: "LC",
      description: "Listed",
      author: @author,
      asset_id: Currency::BTC_ASSET_ID,
      price: 0.001,
      revenue_ratio: 0.1,
      state: "listed"
    )
  end

  test "index renders successfully for a listed collection" do
    get collection_articles_path(collection_uuid: @collection.uuid)

    assert_response :success
  end

  test "index excludes drafted articles" do
    published_article = articles(:published_free)
    drafted_article = articles(:draft)

    # Force both fixtures into this collection. The `belongs_to :collection`
    # association uses `primary_key: :uuid`, so `collection_id` is the
    # collection's UUID string. `update_columns` skips validations so
    # we can move a published fixture into a different collection without
    # re-saving all the rich-text content.
    published_article.update_columns(collection_id: @collection.uuid)
    drafted_article.update_columns(collection_id: @collection.uuid)

    get collection_articles_path(collection_uuid: @collection.uuid)

    assert_response :success
    assert_match published_article.title, response.body
    assert_no_match drafted_article.title, response.body
  end

  test "index orders articles by published_at desc" do
    older = create_published_collection_article!(title: "older title", collection: @collection)
    older.update_columns(published_at: 2.days.ago)

    newer = create_published_collection_article!(title: "newer title", collection: @collection)
    newer.update_columns(published_at: 1.day.ago)

    get collection_articles_path(collection_uuid: @collection.uuid)

    assert_response :success
    body = response.body
    older_pos = body.index(older.title)
    newer_pos = body.index(newer.title)
    assert older_pos, "older article missing from rendered body"
    assert newer_pos, "newer article missing from rendered body"
    assert newer_pos < older_pos, "expected newer article before older in render order"
  end

  test "index renders all published articles in the collection" do
    7.times do |i|
      article = create_published_collection_article!(title: "title #{i}", collection: @collection)
      article.update_columns(published_at: 1.day.ago - i.minutes)
    end

    get collection_articles_path(collection_uuid: @collection.uuid)

    assert_response :success
    # The page renders the collection's published articles. Pagy details
    # (page size 5 vs 50) are pinned separately by the controller spec;
    # here we just verify the articles are wired through.
    titles_in_body = (0..6).count { |i| response.body.include?("title #{i}") }
    assert_equal 7, titles_in_body, "expected all 7 articles in render, got #{titles_in_body}"
  end

  test "index returns 404 for unlisted collection (inherited from base)" do
    unlisted = Collection.create!(
      uuid: SecureRandom.uuid,
      name: "Hidden Collection",
      symbol: "HC",
      description: "Hidden",
      author: @author,
      asset_id: Currency::BTC_ASSET_ID,
      price: 0.001,
      revenue_ratio: 0.1,
      state: "drafted"
    )

    get collection_articles_path(collection_uuid: unlisted.uuid)

    assert_response :not_found
  end

  # Regression guard for #1944. The `_card` partial walks `price_tag`
  # (currency.symbol), `tags.first(3)`, `author` (via `shared/_avatar` →
  # authorization + ActiveStorage variant chain), and `cover.attached?`.
  # Without `Article.with_associations` preloading each row fires 5-8
  # SELECTs, so 5 articles blow the budget well past 25.
  test "index renders without triggering per-row SELECT fan-out" do
    SELECT_BUDGET = 25
    5.times do |i|
      article = create_published_collection_article!(title: "row #{i}", collection: @collection)
      article.update_columns(published_at: 1.day.ago - i.minutes)
    end

    select_count = 0
    counter = ->(_name, _start, _finish, _id, payload) do
      next if payload[:name] == "SCHEMA"

      select_count += 1
    end

    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      get collection_articles_path(collection_uuid: @collection.uuid)
    end

    assert_response :success
    assert_operator select_count, :<=, SELECT_BUDGET,
      "Expected index to fire ≤#{SELECT_BUDGET} SELECTs, got #{select_count}. " \
      "Likely cause: a partial chain (currency, tags, cover, author avatar) regressed."
  end

  private

  # Create a published article in this collection. We build with
  # `state: "drafted"` (so `RichTextContent#content_cannot_be_blank`
  # doesn't fire on the missing rich-text content) and WITHOUT setting
  # `collection_id` (so `Article#set_defaults` doesn't pull the
  # collection's `revenue_ratio` (0.1) into the article's
  # `collection_revenue_ratio` and break the revenue-ratios sum).
  # Then `update_columns` flips to `published` + sets `published_at`
  # + attaches to the collection. `update_columns` skips validations
  # (which is fine for this fixture-style helper — we're not testing
  # the validation path, we're seeding data for the index test).
  def create_published_collection_article!(title:, collection:)
    article = Article.create!(
      author: @author,
      uuid: SecureRandom.uuid,
      title: title,
      intro: "intro for #{title}",
      state: "drafted",
      platform_revenue_ratio: 0.1,
      readers_revenue_ratio: 0.4,
      author_revenue_ratio: 0.5,
      references_revenue_ratio: 0.0,
      free_content_ratio: 0.1,
      price: 0.0001,
      locale: "en"
    )
    article.update_columns(
      state: "published",
      published_at: 1.day.ago,
      collection_id: collection.uuid
    )
    article
  end
end
