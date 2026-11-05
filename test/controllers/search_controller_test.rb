# frozen_string_literal: true

require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  test "index truncates an oversized query to the length limit" do
    limit = ArticleVisibility::QUERY_LENGTH_LIMIT
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

  # The live search always requests turbo_stream (`search_controller.js`
  # responseKind), but /search is a real route: a direct visit must not raise
  # UnknownFormat. This is also the request RackAttackTest makes 21 times.
  test "index renders for a plain html visit" do
    get search_path(query: "author")

    assert_response :success
  end

  test "index preloads the avatar chain for its user hits" do
    seed_searchable_users

    queries = capture_sql do
      get search_path(query: "zeta"), as: :turbo_stream
    end

    assert_response :success
    assert_match "Zeta Searcher 0", response.body,
      "expected the seeded user hits to render — a budget passing on an " \
      "empty result proves nothing"

    # Measured 4 with the preload (22 before it): the per-row avatar chain
    # fired an authorization + attachment SELECT for every one of the 10
    # hits. The headroom absorbs adapter-level variance without letting a
    # per-row lookup back in.
    assert queries.size <= 8, "expected a full page of user hits (10 users " \
      "with authorizations) to stay within 8 SQL statements, got #{queries.size}"
  end

  private

  # A full page of user hits: ten users sharing one name prefix, each with a
  # Mixin authorization carrying an avatar_url — the worst shape of one
  # keystroke's response. Runs outside the counted block.
  def seed_searchable_users
    10.times do |i|
      user = User.create!(
        uid: "90000#{i}",
        name: "Zeta Searcher #{i}",
        mixin_uuid: SecureRandom.uuid,
        mixin_id: "zeta#{i}"
      )
      UserAuthorization.create!(
        user: user,
        provider: :mixin,
        uid: "zeta-auth-#{i}",
        raw: { user_id: "zeta-auth-#{i}", name: user.name, avatar_url: "https://example.com/zeta#{i}.png" }
      )
    end
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
