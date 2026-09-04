# frozen_string_literal: true

require "test_helper"

class API::ArticlesControllerTest < IntegrationTestCase
  test "show returns 404 for draft without auth" do
    article = articles(:draft)

    get api_article_path(article.uuid), as: :json

    assert_response :not_found
  end

  test "show omits content for unauthorized requests" do
    article = articles(:published_paid)

    get api_article_path(article.uuid), as: :json

    assert_response :success
    body = response.parsed_body
    assert_nil body["content"]
    assert_equal article.uuid, body["uuid"]
  end

  test "show includes content for authorized token" do
    article = articles(:published_paid)
    buyer = users(:reader_one)

    with_quill_bot_stub do
      create_buy_order!(article: article, buyer: buyer)
    end

    get api_article_path(article.uuid), headers: api_headers(access_tokens(:reader_token)), as: :json

    assert_response :success
    assert_equal article.content_body, response.parsed_body["content"]
  end

  test "index returns 404 when author_id does not match a user" do
    get api_articles_path(author_id: "00000000-0000-4000-8000-000000000000"), as: :json

    assert_response :not_found
    assert_equal "Not found", response.parsed_body["message"]
  end

  test "index returns published articles for a known author_id" do
    author = users(:author)

    get api_articles_path(author_id: author.mixin_uuid), as: :json

    assert_response :success
    uuids = response.parsed_body.pluck("uuid")
    assert_includes uuids, articles(:published_paid).uuid
    assert_not_includes uuids, articles(:draft).uuid
  end

  test "index truncates an oversized query param to the length limit" do
    limit = ArticleVisibility::QUERY_LENGTH_LIMIT
    long_query = "a" * (limit + 50)

    get api_articles_path(query: long_query), as: :json

    assert_response :success
    # The response renders fine; the point is that the controller did not
    # forward an unbounded string into the ILIKE pattern. We assert via the
    # generated SQL that the pattern was truncated.
    # (Behavioral smoke test — the truncation unit test lives in the service
    # test; here we just confirm the endpoint does not blow up on a huge query.)
  end

  # Issue #2075: the API used to skip the block rule entirely while the web
  # feed applied it in both directions. That divergence is now an assertion —
  # the catalogue branch hides authors blocked in either direction, exactly
  # like the web.
  test "index applies the two-directional block rule for an authenticated viewer" do
    viewer = users(:reader_one)
    viewer.block_user(users(:author))
    users(:author_zh).block_user(viewer)
    headers = api_headers(access_tokens(:reader_token))

    get api_articles_path(author_id: users(:author).mixin_uuid), headers: headers, as: :json

    assert_response :success
    assert_empty response.parsed_body, "expected authors the viewer blocked to be hidden"

    get api_articles_path(author_id: users(:author_zh).mixin_uuid), headers: headers, as: :json

    assert_response :success
    assert_empty response.parsed_body, "expected authors who blocked the viewer to be hidden"

    get api_articles_path(author_id: users(:author_ja).mixin_uuid), headers: headers, as: :json

    assert_response :success
    assert_includes response.parsed_body.pluck("uuid"), articles(:published_ja).uuid,
      "expected unrelated authors to stay visible"
  end

  test "index keeps the viewer's own articles when another author blocked them" do
    users(:author_zh).block_user(users(:author))

    get api_articles_path, headers: api_headers(access_tokens(:author_token)), as: :json

    assert_response :success
    uuids = response.parsed_body.pluck("uuid")
    assert_includes uuids, articles(:published_paid).uuid,
      "expected the viewer's own articles to survive the blocker predicate"
    assert_not_includes uuids, articles(:published_zh).uuid
  end

  test "index hides the requested author's articles from a viewer they blocked" do
    users(:author).block_user(users(:reader_one))

    get api_articles_path(author_id: users(:author).mixin_uuid),
        headers: api_headers(access_tokens(:reader_token)), as: :json

    assert_response :success
    assert_empty response.parsed_body
  end

  test "index applies no block rule for an anonymous viewer" do
    users(:reader_one).block_user(users(:author))
    users(:author_zh).block_user(users(:reader_one))

    get api_articles_path, as: :json

    assert_response :success
    uuids = response.parsed_body.pluck("uuid")
    assert_includes uuids, articles(:published_paid).uuid
    assert_includes uuids, articles(:published_zh).uuid
  end

  test "index eager-loads the author avatar chain consumed by the JSON template" do
    # Regression guard for the avatar N+1 closed by the
    # `author: User::AVATAR_PRELOADS` include added to
    # `API::ArticlesController#index`. Without the preload, the jbuilder
    # `article.author.avatar_image_url` walks `avatar_attachment` plus
    # its `blob`, and falls back to `authorization&.avatar_url`,
    # firing 2-4 SELECTs per row. The SELECT_BUDGET below fits 1
    # ransack + 1 articles + 1 tags + 1 currencies +
    # 5 authors + 5 authorizations + 5 avatar_attachments + 5 blobs +
    # 5 variant_records + 5 image_attachment blobs ~= 38 total at
    # `limit: 5`. Without the preload, 5 rows × ~4 SELECTs each = ~20
    # extra fan-out SELECTs on top of the above (~58 total).
    assert_select_count_at_most(SELECT_BUDGET) do
      get api_articles_path(limit: 5), as: :json
      assert_response :success
    end
  end

  private

  # SELECT_BUDGET covers 1 ransack (articles) + 1 articles +
  # 1 authors + 1 tags + 1 currencies + 5 authorizations +
  # 5 avatar_attachments + 5 blobs + 5 variant_records +
  # 5 preview_image_attachments + 5 preview_image_blob +
  # 5 image_attachments + 5 image_blobs ~= 38 — well under the
  # legacy-shape budget of ~58. Comfortable headroom.
  SELECT_BUDGET = 50

  def assert_select_count_at_most(budget)
    select_count = 0
    counter = ->(_name, _start, _finish, _id, payload) do
      next if payload[:name] == "SCHEMA"

      select_count += 1
    end

    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      yield
    end

    assert_operator select_count, :<=, budget,
      "Expected index to fire ≤#{budget} SELECTs, got #{select_count}. " \
      "Likely cause: avatar chain (authorization + ActiveStorage) regressed."
  end
end
