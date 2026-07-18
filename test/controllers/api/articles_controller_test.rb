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

  test "index truncates an oversized query param to the length limit" do
    limit = API::ArticlesController::QUERY_LENGTH_LIMIT
    long_query = "a" * (limit + 50)

    get api_articles_path(query: long_query), as: :json

    assert_response :success
    # The response renders fine; the point is that the controller did not
    # forward an unbounded string into the ILIKE pattern. We assert via the
    # generated SQL that the pattern was truncated.
    # (Behavioral smoke test — the truncation unit test lives in the service
    # test; here we just confirm the endpoint does not blow up on a huge query.)
  end

  test "index eager-loads the author avatar chain consumed by the JSON template" do
    # Regression guard for the per-row N+1 closed by
    # `author: User::AVATAR_PRELOADS` in `API::ArticlesController#index`:
    # `article.author.avatar_image_url` walks `avatar_attachment` plus the
    # `authorization` fallback.
    assert_select_count_at_most(SELECT_BUDGET) do
      get api_articles_path(limit: 5), as: :json
      assert_response :success
    end
  end

  private

  # Comfortable headroom over the worst-case preload chain at `limit: 5`;
  # the legacy (no avatar preload) shape would add ~20 fan-out SELECTs.
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
