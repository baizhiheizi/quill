# frozen_string_literal: true

require "test_helper"

class UpvotedCommentsControllerTest < ActionController::TestCase
  tests UpvotedCommentsController

  setup do
    @reader = users(:reader_one)
    @author = users(:author)
    @article = articles(:published_free)
    @comment = Comment.create!(author: @author, commentable: @article, content: "Test comment")
    session[:current_session_id] = Session.create!(
      user: @reader,
      uuid: SecureRandom.uuid,
      info: { "provider" => "mixin" }
    ).uuid
  end

  test "update upvokes a comment" do
    patch :update, params: { id: @comment.id }, format: :turbo_stream

    assert_response :success
    assert @reader.reload.upvote_comment?(@comment)
  end

  test "update swaps a prior downvote for an upvote" do
    @reader.create_action(:downvote, target: @comment)
    assert @reader.reload.downvote_comment?(@comment)

    patch :update, params: { id: @comment.id }, format: :turbo_stream

    assert_response :success
    assert @reader.reload.upvote_comment?(@comment)
    assert_not @reader.reload.downvote_comment?(@comment)
  end

  test "destroy removes the upvote" do
    @reader.create_action(:upvote, target: @comment)

    delete :destroy, params: { id: @comment.id }, format: :turbo_stream

    assert_response :success
    assert_not @reader.reload.upvote_comment?(@comment)
  end

  test "actions redirect to login for unauthenticated access" do
    session.delete(:current_session_id)

    patch :update, params: { id: @comment.id }

    assert_response :redirect
  end
end
