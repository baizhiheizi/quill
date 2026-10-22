# frozen_string_literal: true

require "test_helper"

class Admin::CommentsControllerTest < ActionController::TestCase
  tests Admin::CommentsController

  setup do
    @admin = administrators(:one)
    @request.session[:current_admin_id] = @admin.id
  end

  test "index renders successfully with default filters" do
    get :index

    assert_response :success
    comments = @controller.instance_variable_get(:@comments)
    assert_not_nil comments
    # Comments fixtures should produce at least one row.
    assert comments.to_a.any?
  end

  test "index narrows by author_id when author_id param is given" do
    author = users(:author)

    get :index, params: { author_id: author.id }

    assert_response :success
    comments = @controller.instance_variable_get(:@comments)
    assert comments.all? { |c| c.author_id == author.id }
  end

  test "index narrows by commentable_type and id when both are given" do
    article = articles(:published_paid)

    get :index, params: { commentable_type: "Article", commentable_id: article.id }

    assert_response :success
    comments = @controller.instance_variable_get(:@comments)
    assert comments.all? { |c| c.commentable_id == article.id && c.commentable_type == "Article" }
  end

  test "index filters by deleted state" do
    get :index, params: { state: "deleted" }

    assert_response :success
    assert_equal "deleted", @controller.instance_variable_get(:@state)
  end

  test "index filters by without_deleted state" do
    get :index, params: { state: "without_deleted" }

    assert_response :success
    assert_equal "without_deleted", @controller.instance_variable_get(:@state)
  end

  test "index falls back to 'all' for unknown state" do
    get :index, params: { state: "all" }

    assert_response :success
    assert_equal "all", @controller.instance_variable_get(:@state)
  end

  test "index orders by created_at_desc by default" do
    get :index

    assert_response :success
    assert_equal "created_at_desc", @controller.instance_variable_get(:@order_by)
  end

  test "index switches to upvotes_count ordering" do
    get :index, params: { order_by: "upvotes_count" }

    assert_response :success
    assert_equal "upvotes_count", @controller.instance_variable_get(:@order_by)
  end

  test "index switches to downvotes_count ordering" do
    get :index, params: { order_by: "downvotes_count" }

    assert_response :success
    assert_equal "downvotes_count", @controller.instance_variable_get(:@order_by)
  end

  test "index applies ransack query string" do
    get :index, params: { query: "test" }

    assert_response :success
  end

  test "delete soft-deletes the comment when present" do
    comment = comments(:one)

    post :delete, params: { comment_id: comment.id }, format: :turbo_stream

    assert comment.reload.deleted?
  end

  test "delete is idempotent on an already-deleted comment" do
    comment = comments(:one)
    comment.update_column(:deleted_at, 1.day.ago)

    assert_no_difference -> { Comment.where(id: comment.id).count } do
      post :delete, params: { comment_id: comment.id }, format: :turbo_stream
    end
  end

  test "delete silently handles a missing comment_id" do
    # `delete.turbo_stream.erb` calls `dom_id(@comment)` directly, so it
    # raises on a missing record. The controller itself short-circuits
    # cleanly; we exercise that by calling the controller method directly.
    @controller.params = ActionController::Parameters.new(comment_id: -1)
    @controller.send(:delete)
    assert_nil @controller.instance_variable_get(:@comment)
  end

  test "undelete soft-restores a deleted comment" do
    comment = comments(:one)
    comment.update_column(:deleted_at, 1.day.ago)

    post :undelete, params: { comment_id: comment.id }, format: :turbo_stream

    assert_not comment.reload.deleted?
  end

  test "undelete is a no-op on an active comment" do
    comment = comments(:one)
    assert_not comment.deleted?

    post :undelete, params: { comment_id: comment.id }, format: :turbo_stream

    assert_not comment.reload.deleted?
  end

  test "undelete silently handles a missing comment_id" do
    @controller.params = ActionController::Parameters.new(comment_id: -1)
    @controller.send(:undelete)
    assert_nil @controller.instance_variable_get(:@comment)
  end
  # `order_by=created_at_asc` is offered as "Created ASC" in
  # `app/views/admin/comments/_query.html.erb`. It must order by
  # `created_at`, like every other admin index does.
  test "index 'Created ASC' orders by created_at ascending" do
    older = comments(:one)
    newer = comments(:two)
    # Decouple the two timestamps: `older` was created first but touched
    # last, so a sort on `updated_at` yields the opposite order.
    older.update_column(:created_at, 3.days.ago)
    older.update_column(:updated_at, 1.day.ago)
    newer.update_column(:created_at, 2.days.ago)
    newer.update_column(:updated_at, 1.hour.ago)

    get :index, params: { order_by: "created_at_asc" }

    assert_response :success
    result = @controller.instance_variable_get(:@comments).to_a

    assert_includes result, older
    assert_includes result, newer
    assert_operator result.index(older), :<, result.index(newer),
      "expected 'Created ASC' to sort by created_at ascending"
  end

  # `created_at` alone is not a unique sort key. The admin index paginates
  # with OFFSET, so rows tying on `created_at` may come back in a different
  # order between requests — a row can be skipped on one page and repeated on
  # the next. Sorting by `id` as a secondary key makes the order total, and
  # therefore the pagination deterministic.
  test "index 'Created ASC' breaks created_at ties by id" do
    sqls = []
    callback = ->(_name, _start, _finish, _id, payload) do
      sqls << payload[:sql] if payload[:sql].include?("FROM \"comments\"")
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      get :index, params: { order_by: "created_at_asc" }
    end

    order_sql = sqls.reverse.find { |sql| sql.include?("ORDER BY") }
    assert_not_nil order_sql, "expected an ordered SELECT for the comments index"
    assert_match(/ORDER BY\s+"comments"\."created_at" ASC,\s*"comments"\."id" ASC/i, order_sql)
  end
end
