# frozen_string_literal: true

require "test_helper"

class DownvotedArticlesControllerTest < ActionController::TestCase
  tests DownvotedArticlesController

  setup do
    @reader = users(:reader_one)
    @author = users(:author)
    @article = articles(:published_free)
    session[:current_session_id] = Session.create!(
      user: @reader,
      uuid: SecureRandom.uuid,
      info: { "provider" => "mixin" }
    ).uuid
  end

  test "update downvokes an article when not the author" do
    patch :update, params: { uuid: @article.uuid }, format: :turbo_stream

    assert_response :success
    assert @reader.reload.downvote_article?(@article)
  end

  test "update is a no-op when the user is the author" do
    session[:current_session_id] = Session.create!(
      user: @author,
      uuid: SecureRandom.uuid,
      info: { "provider" => "mixin" }
    ).uuid

    patch :update, params: { uuid: @article.uuid }, format: :turbo_stream

    assert_response :success
    assert_not @author.reload.downvote_article?(@article)
  end

  test "update swaps a prior upvote for a downvote" do
    @reader.create_action(:upvote, target: @article)
    assert @reader.reload.upvote_article?(@article)

    patch :update, params: { uuid: @article.uuid }, format: :turbo_stream

    assert_response :success
    assert @reader.reload.downvote_article?(@article)
    assert_not @reader.reload.upvote_article?(@article)
  end

  test "destroy removes the downvote" do
    @reader.create_action(:downvote, target: @article)

    delete :destroy, params: { uuid: @article.uuid }, format: :turbo_stream

    assert_response :success
    assert_not @reader.reload.downvote_article?(@article)
  end

  test "actions redirect to login for unauthenticated access" do
    session.delete(:current_session_id)

    patch :update, params: { uuid: @article.uuid }

    assert_response :redirect
  end
end
