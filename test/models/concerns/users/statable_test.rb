# frozen_string_literal: true

require "test_helper"

# Covers `Users::Statable#has_unread_notification?` and
# `#unread_notifications_count`, the badge counts rendered in the navbar and
# left bar on every page render for authenticated users. Visibility is a
# column on `noticed_notifications`, so the badge counts exactly what the
# notifications index shows.
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

  test "has_unread_notification? returns false when only non-web notifications exist" do
    build_notification!(event: @mixin_event, type: "UserConnectedNotifier::Notification", web_visible: false)
    build_notification!(event: @mixin_event, type: "UserSafeRegistrationNotifier::Notification", web_visible: false)

    assert_not @user.has_unread_notification?
    assert_equal 0, @user.unread_notifications_count
  end

  test "has_unread_notification? returns true when a web notification is unread" do
    build_notification!(event: @web_event, type: "CollectionListedNotifier::Notification", web_visible: true)

    assert @user.has_unread_notification?
    assert_equal 1, @user.unread_notifications_count
  end

  test "the badge no longer overcounts rows the recipient never sees" do
    build_notification!(event: @web_event, type: "CollectionListedNotifier::Notification", web_visible: false)

    assert_not @user.has_unread_notification?
    assert_equal 0, @user.unread_notifications_count
  end

  test "has_unread_notification? ignores read notifications" do
    notification = build_notification!(event: @web_event, type: "CollectionListedNotifier::Notification", web_visible: true)
    notification.update! read_at: Time.current

    assert_not @user.has_unread_notification?
    assert_equal 0, @user.unread_notifications_count
  end

  test "has_unread_notification? issues a single query without loading rows into Ruby" do
    build_notification!(event: @web_event, type: "CollectionListedNotifier::Notification", web_visible: true)

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

  test "the badge query filters on the denormalised column" do
    build_notification!(event: @web_event, type: "CollectionListedNotifier::Notification", web_visible: true)

    sql = @user.notifications.unread.for_web.to_sql

    assert_match(/"web_visible" = (TRUE|true|'t')/, sql)
    assert_no_match(/"type"/, sql)
  end

  private

  def build_notification!(event:, type:, web_visible:)
    Noticed::Notification.create!(
      type: type,
      recipient: @user,
      event: event,
      web_visible: web_visible
    )
  end
end
