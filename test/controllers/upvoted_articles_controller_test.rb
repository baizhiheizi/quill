# frozen_string_literal: true

require "test_helper"

class UpvotedArticlesControllerTest < ActionController::TestCase
  tests UpvotedArticlesController

  setup do
    @reader = users(:reader_one)
    @author = users(:author)
    # Use a free published article so the ArticlePolicy#vote? gate passes
    # without requiring a real Order.
    @article = articles(:published_free)
    session[:current_session_id] = Session.create!(
      user: @reader,
      uuid: SecureRandom.uuid,
      info: { "provider" => "mixin" }
    ).uuid
  end

  test "update upvokes an article when not the author" do
    patch :update, params: { uuid: @article.uuid }, format: :turbo_stream

    assert_response :success
    assert @reader.reload.upvote_article?(@article)
  end

  test "update is a no-op when the user is the author" do
    session[:current_session_id] = Session.create!(
      user: @author,
      uuid: SecureRandom.uuid,
      info: { "provider" => "mixin" }
    ).uuid

    patch :update, params: { uuid: @article.uuid }, format: :turbo_stream

    assert_response :success
    assert_not @author.reload.upvote_article?(@article)
  end

  test "update swaps a prior downvote for an upvote" do
    @reader.create_action(:downvote, target: @article)
    assert @reader.reload.downvote_article?(@article)

    patch :update, params: { uuid: @article.uuid }, format: :turbo_stream

    assert_response :success
    assert @reader.reload.upvote_article?(@article)
    assert_not @reader.reload.downvote_article?(@article)
  end

  test "destroy removes the upvote" do
    @reader.create_action(:upvote, target: @article)

    delete :destroy, params: { uuid: @article.uuid }, format: :turbo_stream

    assert_response :success
    assert_not @reader.reload.upvote_article?(@article)
  end

  test "actions redirect to login for unauthenticated access" do
    session.delete(:current_session_id)

    patch :update, params: { uuid: @article.uuid }

    assert_response :redirect
  end
end
