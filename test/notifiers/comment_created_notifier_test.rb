# frozen_string_literal: true

require "test_helper"

class CommentCreatedNotifierTest < ActiveSupport::TestCase
  setup do
    @author = users(:author)
    @commenter = users(:reader_one)
    @recipient = users(:reader_two)
    @article = articles(:published_paid)
    ensure_notification_setting!(@recipient)
    @comment = Comment.create!(
      author: @commenter,
      commentable: @article,
      content: "Great article!"
    )
  end

  test "message names the commenter and the commented article" do
    deliver_notifier!(CommentCreatedNotifier, record: @comment, comment: @comment, recipient: @recipient)

    notification = notification_for(@recipient)

    assert_includes notification.message, @commenter.name
    assert_includes notification.message, @article.title
  end

  test "url anchors to the comment on the article page" do
    deliver_notifier!(CommentCreatedNotifier, record: @comment, comment: @comment, recipient: @recipient)

    assert_includes notification_for(@recipient).url, "comment_#{@comment.id}"
  end

  test "a recipient who blocked the commenter keeps the row out of the inbox" do
    @recipient.create_action(:block, target: @commenter)

    deliver_notifier!(CommentCreatedNotifier, record: @comment, comment: @comment, recipient: @recipient)

    assert_not notification_for(@recipient).web_visible?
  end
end
