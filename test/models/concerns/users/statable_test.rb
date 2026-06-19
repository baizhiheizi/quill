# frozen_string_literal: true

require "test_helper"

# Covers `Users::Statable#has_unread_notification?` and
# `#unread_notifications_count`, the badge counts rendered in the navbar and
# left bar on every page render for authenticated users. The previous
# implementation loaded every unread notification into Ruby and filtered via
# `select(&:visible_in_web?)`; these tests pin the new SQL-only behavior.
class Users::StatableTest < ActiveSupport::TestCase
  setup do
    @user = users(:reader_one)
    @user.notifications.destroy_all
    Noticed::Event.where(record: @user).delete_all
    @web_event = Noticed::Event.create!(type: "CollectionListedNotifier", record: @user)
    @mixin_event = Noticed::Event.create!(type: "UserConnectedNotifier", record: @user)
  end

  test "has_unread_notification? returns false when there are no notifications" do
    assert_not @user.has_unread_notification?
    assert_equal 0, @user.unread_notifications_count
  end

  test "has_unread_notification? returns false when only mixin-only notifications exist" do
    Noticed::Notification.create!(type: "UserConnectedNotifier::Notification", recipient: @user, event: @mixin_event)
    Noticed::Notification.create!(type: "UserSafeRegistrationNotifier::Notification", recipient: @user, event: @mixin_event)

    assert_not @user.has_unread_notification?
    assert_equal 0, @user.unread_notifications_count
  end

  test "has_unread_notification? returns true when a web notification is unread" do
    Noticed::Notification.create!(type: "CollectionListedNotifier::Notification", recipient: @user, event: @web_event)

    assert @user.has_unread_notification?
    assert_equal 1, @user.unread_notifications_count
  end

  test "has_unread_notification? ignores read notifications" do
    notification = Noticed::Notification.create!(type: "CollectionListedNotifier::Notification", recipient: @user, event: @web_event)
    notification.update!(read_at: Time.current)

    assert_not @user.has_unread_notification?
    assert_equal 0, @user.unread_notifications_count
  end

  test "has_unread_notification? issues a single query without loading rows into Ruby" do
    Noticed::Notification.create!(type: "CollectionListedNotifier::Notification", recipient: @user, event: @web_event)

    queries = []
    callback = ->(*, payload) {
      next if payload[:name] == "SCHEMA"
      queries << payload[:sql]
    }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      @user.has_unread_notification?
    end
    has_unread_queries = queries.grep(/noticed_notifications/)
    assert_equal 1, has_unread_queries.size, "expected a single noticed_notifications SELECT, got: #{has_unread_queries.inspect}"
    assert_match(/LIMIT|EXISTS/i, has_unread_queries.first, "expected LIMIT / EXISTS short-circuit, got: #{has_unread_queries.first}")
  end
end
