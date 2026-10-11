# frozen_string_literal: true

require "test_helper"

class NoticedNotificationTest < ActiveSupport::TestCase
  setup do
    @user = users(:reader_one)
    @article = articles(:published_paid)
  end

  test "for_web is the denormalised column, not the notifier type" do
    deliver_notifier!(UserConnectedNotifier, record: @user, user: @user, recipient: @user)
    deliver_notifier!(CollectionListedNotifier, record: collections(:one), collection: collections(:one), recipient: @user)

    assert_equal 1, @user.notifications.for_web.count
    assert_equal true, @user.notifications.for_web.pick(:web_visible)
    assert_equal "CollectionListedNotifier::Notification", @user.notifications.for_web.pick(:type)
  end

  test "for_web does not consult the notifier class" do
    sql = @user.notifications.for_web.to_sql

    assert_match(/"web_visible" = (TRUE|true|'t')/, sql)
    assert_no_match(/"type"/, sql)
  end
end
