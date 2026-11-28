# frozen_string_literal: true

require "test_helper"

class ArticleReferencesControllerTest < ActionController::TestCase
  tests ArticleReferencesController

  # The route carries `defaults: { format: :json }`, so no `format:` param is
  # needed below.
  setup do
    session[:current_session_id] = sign_in(users(:reader_one)).uuid
  end

  # The reference picker is an access listing (bought / own / free), so the
  # block rule is deliberately not applied here — same reason
  # `ArticleSearchService` skips it for `filter: "bought"`.
  test "index lists bought, owned and free articles for the viewer" do
    article = articles(:published_paid)

    with_quill_bot_stub do
      create_buy_order!(article: article, buyer: users(:reader_one))
    end

    get :index, format: :json

    assert_response :success
    uuids = response.parsed_body.map { |a| a["id"] }
    assert_includes uuids, article.id, "expected the bought article to be listed"
    assert_includes uuids, articles(:published_free).id, "expected free articles to be listed"
    assert_not_includes uuids, articles(:published_zh).id,
      "expected paid articles by other authors to stay out of the picker"
  end

  test "index never lists the viewer's own drafts" do
    session[:current_session_id] = sign_in(users(:author)).uuid

    get :index, format: :json

    assert_response :success
    uuids = response.parsed_body.map { |a| a["id"] }
    assert_includes uuids, articles(:published_paid).id
    assert_not_includes uuids, articles(:draft).id
  end

  # Issue #2075: this surface used to build a third, case-sensitive or-query
  # (`title_cont` …) and union three queries in Ruby. It now goes through the
  # same `ArticleVisibility#searching` the web feed uses, so the match is
  # case-insensitive like every other search on the platform.
  test "index searches case-insensitively across title, intro, author and tags" do
    queries = capture_sql { get :index, params: { query: "FREE ARTICLE" }, format: :json }

    assert_response :success
    assert_includes response.parsed_body.map { |a| a["id"] }, articles(:published_free).id,
      "expected the uppercase query to match case-insensitively"

    main = queries.find { |q| q.include?('FROM "articles"') }
    assert_no_match(/\bLIKE\b/, main, "expected ILIKE, not the old case-sensitive LIKE, got: #{main}")
  end

  test "index caps an oversized query before it reaches SQL" do
    long_query = "a" * (ArticleVisibility::QUERY_LENGTH_LIMIT + 50)

    queries = capture_sql { get :index, params: { query: long_query }, format: :json }

    main = queries.find { |q| q.include?('FROM "articles"') }
    assert_no_match(/#{Regexp.escape(long_query)}/, main,
      "expected the oversized query to be truncated before SQL")
  end

  # The picker serialises `author.name`, `author.avatar_image_url` and
  # `author.mixin_uuid` for every row, and it is not paginated — without a
  # preload each row costs a fresh users SELECT (plus attachment/authorization
  # lookups inside the avatar), so a viewer with many reachable articles pays
  # a users query per article.
  test "index preloads authors so serialising rows costs one users query" do
    create_free_published_article(author: users(:author_zh), title: "Free zh two")
    create_free_published_article(author: users(:author_ja), title: "Free ja two")

    queries = capture_sql { get :index, format: :json }

    assert_response :success
    assert_operator response.parsed_body.length, :>=, 3,
      "expected the picker to list at least three articles by distinct authors"

    users_queries = queries.count { |q| q.include?('FROM "users"') }
    # One query resolves the signed-in viewer, one preload covers every row's
    # author regardless of how many articles the viewer can reach.
    assert users_queries <= 2,
      "expected at most 2 users queries (viewer + author preload), got #{users_queries}"
  end

  private

  def create_free_published_article(author:, title:)
    article = Article.create!(
      title: title,
      intro: "A free article intro.",
      content: "<p>A free article body.</p>",
      author: author,
      price: 0.0,
      state: "published",
      locale: "en"
    )
    # published_at is set after create so the "frozen attributes once
    # published" guard (which fires while asset_id is still dirty) doesn't
    # reject the new record.
    article.update_columns(published_at: 2.days.ago)
    article
  end

  def capture_sql
    queries = []
    sub = ActiveSupport::Notifications.subscribe("sql.active_record") do |_, _, _, _, payload|
      queries << payload[:sql] unless payload[:name] == "SCHEMA"
    end
    yield
    queries
  ensure
    ActiveSupport::Notifications.unsubscribe(sub) if sub
  end
end
