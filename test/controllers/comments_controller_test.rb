# frozen_string_literal: true

require "test_helper"

class CommentsControllerTest < ActionController::TestCase
  tests CommentsController

  setup do
    @reader = users(:reader_one)
    session[:current_session_id] = Session.create!(
      user: @reader,
      uuid: SecureRandom.uuid,
      info: { "provider" => "mixin" }
    ).uuid
  end

  test "create rejects comments on inaccessible articles" do
    article = articles(:draft)

    post :create, params: {
      comment: {
        commentable_type: "Article",
        commentable_id: article.id,
        content: "Should not post"
      }
    }, format: :turbo_stream

    assert_response :forbidden
    assert_equal 0, Comment.where(author: @reader).where(commentable_type: "Article").count
  end

  test "create allows comments on published free articles" do
    article = articles(:published_free)

    assert_difference -> { Comment.count }, 1 do
      post :create, params: {
        comment: {
          commentable_type: "Article",
          commentable_id: article.id,
          content: "Nice article"
        }
      }, format: :turbo_stream
    end
  end

  test "new renders reply modal link for quote comment when logged in" do
    get :new, params: { quote_comment_id: comments(:two).id }

    assert_response :ok
    assert_match %r{href="/comments/new\?quote_comment_id=#{comments(:one).id}"}, response.body
  end

  test "quote comment link renders login link for guests" do
    guest_view = Class.new(ApplicationController) do
      def current_user = nil
    end

    html = guest_view.render(
      inline: "<%= render 'comments/quote_comment_link', comment: comment %>",
      locals: { comment: comments(:one) },
      layout: false,
    )

    assert_includes html, %(href="/login?return_to=)
    assert_includes html, %(data-turbo-frame="modal")
    assert_not_includes html, "/comments/new?quote_comment_id"
  end

  test "new redirects guests to root" do
    session.delete(:current_session_id)

    get :new, params: { quote_comment_id: comments(:one).id }

    assert_redirected_to root_path
  end

  test "new returns not found without commentable params" do
    get :new

    assert_response :not_found
  end

  test "new returns not found for unknown commentable id" do
    get :new, params: { commentable_type: "Article", commentable_id: -1 }

    assert_response :not_found
  end

  test "new returns not found for unknown quote comment id" do
    get :new, params: { quote_comment_id: -1 }

    assert_response :not_found
  end

  test "new renders form for published free article" do
    article = articles(:published_free)

    get :new, params: { commentable_type: "Article", commentable_id: article.id }

    assert_response :ok
    assert_match %r{name="comment\[commentable_id\]"}, response.body
  end

  test "new renders form for quote comment" do
    get :new, params: { quote_comment_id: comments(:one).id }

    assert_response :ok
    assert_match %r{name="comment\[quote_comment_id\]"}, response.body
  end

  test "new rejects unauthorized articles" do
    article = articles(:draft)

    get :new, params: { commentable_type: "Article", commentable_id: article.id }

    assert_redirected_to root_path
  end

  test "index serves a signed-in page inside a flat query budget" do
    article = articles(:published_paid)
    seed_comment_page(article)
    @reader.create_action(:upvote, target: article.comments.first)
    @reader.create_action(:downvote, target: article.comments.second)

    count = count_sql_statements do
      get :index, params: { article_uuid: article.uuid }
    end

    assert_response :ok
    # Measured 22 with the full preload (69 before it); the headroom absorbs
    # adapter-level variance without letting a per-row lookup back in.
    assert count <= 24, "expected the signed-in comments page (13 comments, several " \
      "authors, one quote chain) to stay within 24 SQL statements, got #{count}"
  end

  test "index serves a guest page inside a flat query budget" do
    session.delete(:current_session_id)
    article = articles(:published_paid)
    seed_comment_page(article)

    count = count_sql_statements do
      get :index, params: { article_uuid: article.uuid }
    end

    assert_response :ok
    # Measured 14 with the full preload (39 before it).
    assert count <= 16, "expected the guest comments page (13 comments, several " \
      "authors, one quote chain) to stay within 16 SQL statements, got #{count}"
  end

  test "index primes the viewer vote sets for the rendered page" do
    article = articles(:published_paid)
    upvoted = article.comments.first
    downvoted = article.comments.second
    @reader.create_action(:upvote, target: upvoted)
    @reader.create_action(:downvote, target: downvoted)

    get :index, params: { article_uuid: article.uuid }

    assert_response :ok
    upvoted_ids = @controller.instance_variable_get(:@preloaded_upvoted_comment_ids)
    downvoted_ids = @controller.instance_variable_get(:@preloaded_downvoted_comment_ids)
    assert_includes upvoted_ids, upvoted.id
    assert_includes downvoted_ids, downvoted.id
    # Only page ids are primed, so a vote on a comment outside the page
    # never inflates the set the partial consults.
    assert_equal 2, upvoted_ids.size + downvoted_ids.size
  end

  private

  # A representative page: 11 fresh comments on top of the two fixture rows
  # (13 total, several distinct authors so the avatar chains vary, one quote
  # chain), the worst shape of the public list. Runs outside the counted
  # block — only the request itself is measured.
  def seed_comment_page(article)
    authors = [ users(:author), users(:reader_two), users(:author_zh), users(:author_ja), @reader ]
    seeded = []

    11.times do |i|
      seeded << Comment.create!(
        author: authors[i % authors.size],
        commentable: article,
        content: "Seeded comment #{i} on the comments-index page"
      )
    end

    Comment.create!(
      author: users(:reader_two),
      commentable: article,
      content: "A reply quoting the first seeded comment",
      quote_comment: seeded.first
    )
  end

  # Counts every SQL statement the block issues, including the ones served
  # from the per-request query cache. `assert_queries_count` drops cached
  # queries, so it cannot see a repeated lookup that the cache absorbed.
  # (Same helper as `ArticleTest`; kept local so the bounds stay next to the
  # scenario that measured them.)
  def count_sql_statements
    count = 0
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      count += 1 unless payload[:name] == "SCHEMA"
    end
    yield
    count
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end
end
