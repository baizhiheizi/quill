# frozen_string_literal: true

require "test_helper"

# Controller-level coverage for the public comment tab on a user's profile.
# The action renders polymorphic commentables and their authors, so the tests
# also pin the eager-loaded association shape consumed by the view.
class Users::CommentsControllerTest < ActionController::TestCase
  tests Users::CommentsController

  test "index renders comments written by the selected user" do
    author = users(:author)
    comment = comments(:one)

    get :index, params: { user_uid: author.uid }

    assert_response :success
    comments = @controller.instance_variable_get(:@comments).to_a
    assert_includes comments, comment
    assert comments.all? { |record| record.author_id == author.id }
  end

  test "index eager-loads commentable and its author" do
    author = users(:author)

    get :index, params: { user_uid: author.uid }

    assert_response :success
    comment = @controller.instance_variable_get(:@comments).first
    assert comment.association(:commentable).loaded?
    assert comment.association(:author).loaded?
    assert comment.commentable.association(:author).loaded?
  end
end
