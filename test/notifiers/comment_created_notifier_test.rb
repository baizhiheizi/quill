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

  test "deliver creates a visible web notification for subscribers" do
    deliver_notifier!(
      CommentCreatedNotifier,
      record: @comment,
      comment: @comment,
      recipient: @recipient
    )

    notification = notification_for(@recipient)

    assert_includes notification.message, @commenter.name
    assert_includes notification.message, @article.title
    assert notification.visible_in_web?
  end

  test "visible_in_web is false when recipient blocked the comment author" do
    @recipient.create_action(:block, target: @commenter)

    deliver_notifier!(
      CommentCreatedNotifier,
      record: @comment,
      comment: @comment,
      recipient: @recipient
    )

    assert_not notification_for(@recipient).visible_in_web?
  end
end
