# frozen_string_literal: true

require "test_helper"

class Comments::NotifySubscribersJobTest < JobTestCase
  test "perform no-ops for missing comment" do
    assert_nothing_raised { Comments::NotifySubscribersJob.perform_now(-1) }
  end

  test "perform calls notify_subscribers on comment" do
    comment = comments(:one)
    called = false
    comment.define_singleton_method(:notify_subscribers) { called = true }

    stub_class_method(Comment, :find_by, ->(**kwargs) { kwargs[:id] == comment.id ? comment : nil }) do
      Comments::NotifySubscribersJob.perform_now(comment.id)
    end

    assert called
  end

  test "creating a comment offloads the fan-out instead of delivering inline" do
    article = articles(:published_paid)
    reader = users(:reader_one)
    reader.create_action :commenting_subscribe, target: article

    assert_enqueued_with job: Comments::NotifySubscribersJob do
      Comment.create!(author: users(:reader_two), commentable: article, content: "async now")
    end

    # Nothing is delivered during the request any more.
    assert_equal 0, Noticed::Notification.where(recipient: reader).count

    perform_enqueued_jobs

    assert_operator Noticed::Notification.where(recipient: reader).count, :>=, 1
  end
end
