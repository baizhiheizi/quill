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

    queries = []
    callback = ->(*, payload) {
      next if payload[:name] == "SCHEMA"
      queries << payload[:sql]
    }

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      get :active_authors
    end

    # The main users SELECT must inline the block predicate as a subquery
    users_selects = queries.select { |q| q.include?('FROM "users"') }
    assert_predicate users_selects, :any?, "expected at least one FROM \"users\" SELECT"

    main = users_selects.find { |q| q.include?("NOT IN") } || users_selects.first
    assert_match(/NOT\s+IN\s*\(SELECT/i, main,
      "expected active_authors to use NOT IN (SELECT ...) subquery for blocked users, got: #{main}")

    # The implementation must NOT pre-fetch every block_user_ids row into Ruby.
    # `users(:author)` is already loaded by the test, so an `actions.*` SELECT
    # containing the author's id is the signature of the old code path.
    refute_selecting = queries.select { |q|
      q.start_with?("SELECT") && q.include?('FROM "actions"') && q.include?(users(:author).id.to_s)
    }
    assert_empty refute_selecting,
      "expected no SELECT on actions loading the blocked author id, got: #{refute_selecting.inspect}"
  end

  test "active_authors works for guest users (no current_user, no block filter SQL)" do
    # Drop the signed-in session
    @request.session[:current_session_id] = nil

    queries = []
    callback = ->(*, payload) {
      next if payload[:name] == "SCHEMA"
      queries << payload[:sql]
    }

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      get :active_authors
    end

    users_selects = queries.select { |q| q.include?('FROM "users"') }
    assert_predicate users_selects, :any?, "expected at least one FROM \"users\" SELECT"

    main = users_selects.find { |q| q.include?("NOT IN") } || users_selects.first
    assert_no_match(/NOT\s+IN\s*\(SELECT/i, main,
      "expected no NOT IN subquery when @current_user is nil (guard clause), got: #{main}")

    # The guest path must not touch the actions table at all
    actions_selects = queries.select { |q| q.start_with?("SELECT") && q.include?('FROM "actions"') }
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

  test "hot_tags samples at the SQL level with LIMIT 5 (not LIMIT 50 + Ruby sample)" do
    # The previous shape loaded `.limit(50)` and then called `.sample(5)` in
    # Ruby, which meant ActiveRecord issued a 50-row fetch plus a separate
    # COUNT + OFFSET round-trip for the sample. The new shape does both in
    # one query: `... ORDER BY ... RANDOM() LIMIT 5`. We can't reliably
    # assert the cache round-trip here (test env uses `:null_store`), so we
    # pin the SQL shape instead.
    queries = []
    callback = ->(*, payload) {
      next if payload[:name] == "SCHEMA"
      next if payload[:sql].include?("solid_cache_entries")
      queries << payload[:sql]
    }

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      get :hot_tags
    end

    tag_selects = queries.select { |q| q.start_with?("SELECT") && q.include?('FROM "tags"') }
    assert_predicate tag_selects, :any?,
      "expected at least one FROM \"tags\" SELECT, got: #{queries.inspect}"

    main = tag_selects.first
    # `RANDOM()` may be appended to the existing `Tag.hot` ORDER BY (which
    # already orders by `COUNT(articles.id) DESC, tags.created_at DESC`),
    # so check for the `RANDOM()` token rather than an exact match.
    assert_match(/RANDOM\(\)/i, main,
      "expected RANDOM() in the ORDER BY at the SQL level, got: #{main}")
    assert_match(/LIMIT\s+\$4|limit\s+5/i, main,
      "expected LIMIT 5 (not 50) at the SQL level, got: #{main}")

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
end
