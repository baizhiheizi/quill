# frozen_string_literal: true

require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  test "index truncates an oversized query to the length limit" do
    limit = SearchController::QUERY_LENGTH_LIMIT
    long_query = "a" * (limit + 50)

    queries = capture_sql do
      get search_path(query: long_query), as: :turbo_stream
    end

    user_or_tag_query = queries.find { |q| q =~ /(FROM "users"|FROM "tags")/i }
    assert user_or_tag_query, "expected a users/tags query to be issued"
    # The original oversized query must never reach SQL; the truncated prefix
    # is what should appear in the ILIKE pattern.
    assert_no_match(/#{Regexp.escape(long_query)}/, user_or_tag_query,
      "expected the oversized query to be truncated before SQL")
    truncated = "a" * limit
    assert_match(/#{truncated}/, user_or_tag_query,
      "expected the ILIKE pattern to be truncated to #{limit} chars")
  end

  test "index renders for a normal query" do
    get search_path(query: "author"), as: :turbo_stream

    assert_response :success
  end

  private

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
