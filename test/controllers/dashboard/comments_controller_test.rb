# frozen_string_literal: true

require "test_helper"

# `Dashboard::CommentsController#index` renders two partials:
# - `app/views/dashboard/comments/_article_comment.html.erb` walks
#   `comment.author.avatar_image_thumb` via `shared/avatar` with `thumb: true`.
# - `_article_comment.html.erb` and `_comment.html.erb` reference
#   `comment.commentable` (polymorphic) and `comment.commentable.author`
#   (for the article link).
# Before this PR the controller eager-loaded only `:author` (and
# `commentable: :author` in the all-comments branch), so each row fired
# ~5 extra SELECTs for the ActiveStorage avatar chain. The regression-guard
# below asserts the index action completes in a small bounded number of
# SELECTs even when the user has many comments by different authors (the
# worst case for the per-row fan-out).
class Dashboard::CommentsControllerTest < ActionController::TestCase
  tests Dashboard::CommentsController

  # 1 pagy count + 1 comments SELECT + 1 authors SELECT (5 unique authors) +
  # 4-5 ActiveStorage SELECTs (auth + attachment + blob + variant_records +
  # image_attachment blob) for the union of preloaded rows. Comfortably
  # under 20. Without the preload, 5 comments × ~5 SELECTs each = ~25.
  SELECT_BUDGET = 20
  COMMENT_COUNT = 5

  setup do
    @reader = users(:reader_one)
    sign_in_as(@reader)
  end

  test "article-scoped index renders without triggering per-row avatar SELECT fan-out" do
    article = articles(:published_paid)
    seed_comments!(article: article, count: COMMENT_COUNT)

    assert_select_count_within_budget do
      get :index, params: { article_uuid: article.uuid }
    end
  end

  test "all-comments index renders without triggering per-row avatar SELECT fan-out" do
    seed_user_comments!(count: COMMENT_COUNT)

    assert_select_count_within_budget do
      get :index
    end
  end

  private

  def sign_in_as(user)
    test_session = sign_in(user)
    @request.session[:current_session_id] = test_session.uuid
  end

  def assert_select_count_within_budget
    select_count = 0
    counter = ->(_name, _start, _finish, _id, payload) do
      next if payload[:name] == "SCHEMA"

      select_count += 1
    end

    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      yield
    end

    assert_response :success
    assert_operator select_count, :<=, SELECT_BUDGET,
      "Expected index to fire ≤#{SELECT_BUDGET} SELECTs, got #{select_count}. " \
      "Likely cause: avatar chain (authorization + ActiveStorage) regressed."
  end

  # Each comment gets a unique author so the per-row avatar fan-out is
  # observable — Rails' identity-map cache hides it when all rows share an
  # author.
  def seed_comments!(article:, count:)
    needed = count - article.comments.count
    needed.times do |i|
      Comment.create!(
        author: create_unique_author!("Commenter #{i}"),
        commentable: article,
        legacy_markdown_content: "Test comment #{i}",
        created_at: i.hours.ago
      )
    end
  end

  def seed_user_comments!(count:)
    needed = count - @reader.comments.count
    article = articles(:published_paid)
    needed.times do |i|
      Comment.create!(
        author: @reader,
        commentable: article,
        legacy_markdown_content: "User-scoped comment #{i}",
        created_at: i.hours.ago
      )
    end
  end

  def create_unique_author!(name)
    User.create!(
      uid: SecureRandom.hex(8),
      name: name,
      mixin_uuid: SecureRandom.uuid,
      mixin_id: SecureRandom.random_number(1_000_000_000).to_s
    )
  end
end
