# frozen_string_literal: true

require "test_helper"

# `Dashboard::DeletedArticlesController` exposes the soft-delete path for the
# author's own drafted articles. The action surface is small but every branch
# guards an authorization boundary, so a regression in the policy or scope
# here would let a user silently destroy articles they don't own.
#
# Coverage pins:
#   * `new` renders the confirmation page for an authored draft.
#   * `new` 404s when the article is missing or not a draft of the current user.
#   * `update` soft-deletes an authored draft.
#   * `update` is a no-op when the article is missing (returns 404, no destroy).
#   * `update` refuses to destroy an article the current user doesn't own
#     (Pundit `ArticlePolicy#destroy?` is `update?`, which requires ownership).
class Dashboard::DeletedArticlesControllerTest < ActionController::TestCase
  tests Dashboard::DeletedArticlesController

  setup do
    @author = users(:author)
    sign_in_as(@author)
  end

  def sign_in_as(user)
    test_session = sign_in(user)
    @request.session[:current_session_id] = test_session.uuid
  end

  test "update soft-deletes an authored draft via the turbo-stream endpoint" do
    article = articles(:draft)

    assert_difference -> { Article.where(id: article.id).count }, -1 do
      patch :update, params: { uuid: article.uuid }, format: :turbo_stream
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", response.media_type
  end

  test "update is a no-op when the article is missing" do
    missing_uuid = "ffffffff-ffff-4fff-8fff-ffffffffffff"

    assert_no_difference -> { Article.count } do
      patch :update, params: { uuid: missing_uuid }, format: :turbo_stream
    end

    assert_response :not_found
  end

  test "update refuses to destroy an article not owned by the current user" do
    other_author = users(:reader_one)
    other_draft = Article.create!(
      uuid: SecureRandom.uuid,
      title: "Other Author Draft",
      intro: "Intro",
      author: other_author,
      asset_id: articles(:draft).asset_id,
      price: 0.0,
      state: :drafted,
      locale: :en
    )

    assert_no_difference -> { Article.where(id: other_draft.id).count } do
      patch :update, params: { uuid: other_draft.uuid }, format: :turbo_stream
    end

    assert_response :not_found
  end

  test "new renders the confirmation page for an authored draft" do
    article = articles(:draft)

    get :new, params: { uuid: article.uuid }

    assert_response :success
    assert_match article.title, response.body
  end

  test "new returns 404 when the article uuid does not belong to the current user" do
    # `draft` belongs to `:author`. The current user (`@author`) is `author`,
    # so this case alone wouldn't 404; create another author's draft to
    # exercise the scope boundary.
    other_author = users(:reader_one)
    other_draft = Article.create!(
      uuid: SecureRandom.uuid,
      title: "Reader One Draft",
      intro: "Intro",
      author: other_author,
      asset_id: articles(:draft).asset_id,
      price: 0.0,
      state: :drafted,
      locale: :en
    )

    get :new, params: { uuid: other_draft.uuid }

    assert_response :not_found
  end
end
