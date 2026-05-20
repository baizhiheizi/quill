# frozen_string_literal: true

require "test_helper"

class NoticedNotificationTest < ActiveSupport::TestCase
  setup do
    @user = users(:reader_one)
    @article = articles(:published_paid)
  end

  test "for_web scope excludes mixin-only notifier types" do
    deliver_notifier!(UserConnectedNotifier, record: @user, user: @user, recipient: @user)
    deliver_notifier!(ArticleImportedNotifier, record: @article, article: @article, recipient: @user)

    assert_equal 1, @user.notifications.for_web.count
    assert_equal "ArticleImportedNotifier::Notification", @user.notifications.for_web.pick(:type)
  end
end
