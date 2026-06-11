# frozen_string_literal: true

require "test_helper"

class CommentDeletedNotifierTest < ActiveSupport::TestCase
  setup do
    @commenter = users(:reader_one)
    @recipient = users(:author)
    @article = articles(:published_paid)
    @comment = Comment.create!(
      author: @commenter,
      commentable: @article,
      legacy_markdown_content: "Will be deleted"
    )
  end

  test "deliver creates a visible web notification with article title and deleted message" do
    deliver_notifier!(
      CommentDeletedNotifier,
      record: @comment,
      comment: @comment,
      recipient: @recipient
    )

    notification = notification_for(@recipient)

    assert_includes notification.message, @article.title
    assert_includes notification.message, I18n.t("notifiers.comment_deleted_notifier.notification.deleted")
    assert notification.visible_in_web?
  end

  test "url anchors to the deleted comment" do
    deliver_notifier!(
      CommentDeletedNotifier,
      record: @comment,
      comment: @comment,
      recipient: @recipient
    )

    notification = notification_for(@recipient)

    assert_includes notification.url, @article.uuid
    assert_includes notification.url, "comment_#{@comment.id}"
  end

  test "deliver enqueues mixin bot delivery for messenger recipients" do
    assert @recipient.messenger?

    deliver_notifier!(
      CommentDeletedNotifier,
      record: @comment,
      comment: @comment,
      recipient: @recipient
    )

    assert_enqueued_jobs 1, only: Noticed::EventJob

    perform_enqueued_jobs only: Noticed::EventJob

    assert_enqueued_jobs 1, only: DeliveryMethods::MixinBot
  end
end
