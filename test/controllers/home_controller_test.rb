# frozen_string_literal: true

require "test_helper"

class HomeControllerTest < ActionController::TestCase
  tests HomeController

  # Don't render the view (no `application.css` in test env). We only care
  # about the SQL emitted and the `@users` instance variable.
  setup do
    HomeController.send(:define_method, :render) { |*| response_body || "" }
    @user = users(:reader_one)
    @test_session = sign_in(@user)
    @request.session[:current_session_id] = @test_session.uuid
  end

  teardown do
    HomeController.send(:remove_method, :render) if HomeController.method_defined?(:render, false)
  end

  test "active_authors inlines blocked users as a SQL subquery (no Ruby materialization)" do
    # Block the author so the predicate is actually exercised
    @user.block_user(users(:author))

    queries = capture_queries { get :active_authors }

    # The main users SELECT must inline the block predicate as a subquery
    main = main_users_select(queries)
    assert_not_nil main, "expected at least one FROM \"users\" SELECT"

    assert_match(/NOT\s+IN\s*\(SELECT/i, main,
      "expected active_authors to use NOT IN (SELECT ...) subquery for blocked users, got: #{main}")

    # The implementation must NOT pre-fetch every block_user_ids row into Ruby.
    # `users(:author)` is already loaded by the test, so an `actions.*` SELECT
    # containing the author's id is the signature of the old code path.
    refute_selecting = queries.select { |q|
      q[:sql].start_with?("SELECT") && q[:sql].include?('FROM "actions"') && q[:sql].include?(users(:author).id.to_s)
    }
    assert_empty refute_selecting,
      "expected no SELECT on actions loading the blocked author id, got: #{refute_selecting.inspect}"
  end

  test "active_authors works for guest users (no current_user, no block filter SQL)" do
    # Drop the signed-in session
    @request.session[:current_session_id] = nil

    queries = capture_queries { get :active_authors }

    main = main_users_select(queries)
    assert_not_nil main, "expected at least one FROM \"users\" SELECT"

    assert_no_match(/NOT\s+IN\s*\(SELECT/i, main,
      "expected no NOT IN subquery when @current_user is nil (guard clause), got: #{main}")

    # The guest path must not touch the actions table at all
    actions_selects = queries.select { |q| q[:sql].start_with?("SELECT") && q[:sql].include?('FROM "actions"') }
    assert_empty actions_selects, "expected no SELECT on actions when @current_user is nil"
  end

  test "active_authors excludes the signed-in user from the result" do
    # The signed-in user must never appear in @users, regardless of the SQL shape
    get :active_authors

    result = @controller.instance_variable_get(:@users).to_a
    assert_not_includes result.map(&:id), @user.id
  end

  test "active_authors excludes blocked users from the result" do
    author = users(:author)
    @user.block_user(author)

    get :active_authors

    result = @controller.instance_variable_get(:@users).to_a
    assert_not_includes result.map(&:id), author.id
  end

  test "active_authors samples at the SQL level with LIMIT 5 (not LIMIT 20 + Ruby sample)" do
    # Same SQL-sample pattern as `hot_tags`. The previous shape loaded
    # `.limit(20)` then called `.sample(5)` in Ruby. The new shape lets
    # Postgres pick 5 rows directly via `ORDER BY RANDOM() LIMIT 5`. We
    # can't assert cache behavior here (test env uses `:null_store`); pin
    # the SQL shape instead.
    queries = capture_queries { get :active_authors }

    main = main_users_select(queries)
    assert_not_nil main, "expected at least one FROM \"users\" SELECT"

    assert_match(/RANDOM\(\)/i, main,
      "expected RANDOM() in the ORDER BY at the SQL level, got: #{main}")
    # The LIMIT placeholder index depends on how many binds come before it
    # (e.g. the NOT IN (SELECT ...) block-filter subquery adds 3). Assert
    # against the bound parameter instead of the placeholder number.
    assert_equal 5, limit_value_for(main, queries),
      "expected LIMIT 5 (not 20) at the SQL level, got: #{main}"

    # `@users` must be a materialized Array — not an AR relation still
    # capable of issuing more queries.
    result = @controller.instance_variable_get(:@users)
    assert_kind_of Array, result
    assert_operator result.length, :<=, 5
  end

  test "hot_tags samples at the SQL level with LIMIT 5 (not LIMIT 50 + Ruby sample)" do
    # The previous shape loaded `.limit(50)` and then called `.sample(5)` in
    # Ruby, which meant ActiveRecord issued a 50-row fetch plus a separate
    # COUNT + OFFSET round-trip for the sample. The new shape does both in
    # one query: `... ORDER BY ... RANDOM() LIMIT 5`. We can't reliably
    # assert the cache round-trip here (test env uses `:null_store`), so we
    # pin the SQL shape instead.
    queries = capture_queries(exclude: [ "solid_cache_entries" ]) { get :hot_tags }

    tag_selects = queries.select { |q| q[:sql].start_with?("SELECT") && q[:sql].include?('FROM "tags"') }
    assert_predicate tag_selects, :any?,
      "expected at least one FROM \"tags\" SELECT, got: #{queries.inspect}"

    main = tag_selects.first[:sql]
    # `RANDOM()` may be appended to the existing `Tag.hot` ORDER BY (which
    # already orders by `COUNT(articles.id) DESC, tags.created_at DESC`),
    # so check for the `RANDOM()` token rather than an exact match.
    assert_match(/RANDOM\(\)/i, main,
      "expected RANDOM() in the ORDER BY at the SQL level, got: #{main}")
    assert_equal 5, limit_value_for(main, queries),
      "expected LIMIT 5 (not 50) at the SQL level, got: #{main}"

    # `@hot_tags` must be a materialized Array — not an AR relation still
    # capable of issuing more queries.
    result = @controller.instance_variable_get(:@hot_tags)
    assert_kind_of Array, result
    assert_operator result.length, :<=, 5
  end

  test "hot_tags is called as a public action and assigns @hot_tags" do
    # The endpoint is mounted as a turbo-frame src (`/hot_tags`) by
    # `app/views/articles/_widgets.html.erb`. Verify the action is routed
    # and assigns the instance variable.
    get :hot_tags
    assert_response :success
    assert_not_nil @controller.instance_variable_get(:@hot_tags)
  end

  # Cross-Locale Article Visibility (US3, FR-004):
  # `hot_tags` must not apply a `tags.locale = caller_locale` predicate.
  # The previous code narrowed the relation to the visitor's locale; after
  # the redesign the tags module surfaces every language.
  test "hot_tags does not emit a WHERE tags.locale = ? predicate" do
    # Force a Chinese-locale session so the caller's preferred locale
    # would be the filter value if the old code path was still in place.
    @request.session[:current_locale] = "zh-CN"

    queries = capture_queries(exclude: [ "solid_cache_entries" ]) { get :hot_tags }

    tag_selects = queries.select { |q| q[:sql].start_with?("SELECT") && q[:sql].include?('FROM "tags"') }
    assert_predicate tag_selects, :any?,
      "expected at least one FROM \"tags\" SELECT, got: #{queries.inspect}"

    main = tag_selects.first[:sql]
    assert_no_match(/"tags"\."locale"\s*=/i, main,
      "expected no `tags.locale = ...` predicate in hot_tags SQL, got: #{main}")
  end

  # Cross-Locale Article Visibility (US3, FR-005):
  # `active_authors` must not apply a `users.locale = caller_locale` predicate.
  test "active_authors does not emit a WHERE users.locale = ? predicate" do
    @request.session[:current_locale] = "zh-CN"

    queries = capture_queries { get :active_authors }

    main = main_users_select(queries)
    assert_not_nil main, "expected at least one FROM \"users\" SELECT"

    assert_no_match(/"users"\."locale"\s*=/i, main,
      "expected no `users.locale = ...` predicate in active_authors SQL, got: #{main}")
  end

  private

  # Captures every SQL query issued by the block (SCHEMA queries excluded).
  # Pass `exclude:` to also drop noise from a known source (e.g. solid_cache).
  # Returns an Array of Hashes with :sql and :binds so callers can inspect
  # bound parameter values, not just the SQL placeholder text.
  def capture_queries(exclude: [], &block)
    queries = []
    callback = ->(*, payload) {
      next if payload[:name] == "SCHEMA"
      next if exclude.any? { |needle| payload[:sql].include?(needle) }
      queries << { sql: payload[:sql], binds: payload[:type_casted_binds] }
    }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &block)
    queries
  end

  # Returns the primary users SELECT — the one whose shape the action
  # controls (the others are session/auth lookups). When the action emits
  # a NOT IN block-filter subquery, prefer that select; otherwise fall
  # back to the first users SELECT.
  def main_users_select(queries)
    users_selects = queries.select { |q| q[:sql].include?('FROM "users"') }
    users_selects.find { |q| q[:sql].include?("NOT IN") }&.dig(:sql) || users_selects.first&.dig(:sql)
  end

  # Resolves the LIMIT value bound to `sql` by looking up its placeholder
  # index in the corresponding binds. The placeholder index isn't stable
  # (it depends on the number of binds that come before LIMIT in the
  # query), so we look it up by index rather than asserting a fixed
  # number.
  def limit_value_for(sql, queries)
    pair = queries.find { |q| q[:sql] == sql }
    return unless pair

    placeholder = sql[/\bLIMIT\s+\$(\d+)\b/, 1]
    return unless placeholder

    pair[:binds][placeholder.to_i - 1]
  end
end
