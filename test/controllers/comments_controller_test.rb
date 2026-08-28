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

  test "new renders login link for quote comment when logged out" do
    session.delete(:current_session_id)

    get :new, params: { quote_comment_id: comments(:two).id }

    assert_response :ok
    assert_match %r{href="/login\?return_to=}, response.body
    assert_no_match %r{href="/comments/new\?quote_comment_id}, response.body
  end
end
