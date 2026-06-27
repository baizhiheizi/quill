# frozen_string_literal: true

require "test_helper"

# Tests for the Action model — the bridge between action_store gem and
# Noticed::Event / Notifier dispatch. The model is small but every behavior
# is otherwise uncovered:
#
#   * Polymorphic `target` and `user` with `optional: true` (both can be nil).
#   * after_create :notify_target dispatch — only `:subscribe` action_type
#     against a User target reaches SubscribeUserActionCreatedNotifier; every
#     other (action_type, target_type) pair is a silent no-op.
#   * before_destroy :destroy_notifications cascade to noticed_events; the
#     rescue path swallows StandardError and logs instead of failing the
#     destroy.
#   * `#notifications` returns the noticed_events association.
class ActionTest < ActiveSupport::TestCase
  setup do
    @subscriber = users(:reader_one)
    @author = users(:author)
    ensure_notification_setting!(@subscriber)
    @article = articles(:published_paid) if articles(:published_paid)
    Action.skip_callback :create, :after, :notify_target
  end

  teardown do
    Action.set_callback :create, :after, :notify_target
  end

  # ---------------------------------------------------------------- schema / associations

  test "persists with both user and target polymorphic associations" do
    action = Action.create!(
      action_type: "subscribe",
      user: @subscriber,
      user_type: "User",
      target: @author,
      target_type: "User"
    )

    assert action.persisted?
    assert_equal @subscriber, action.user
    assert_equal @author, action.target
  end

  test "persists with a non-User target (polymorphic Article target)" do
    skip "fixture articles(:published_paid) not present" unless @article

    action = Action.create!(
      action_type: "upvote",
      user: @subscriber,
      user_type: "User",
      target: @article,
      target_type: "Article"
    )

    assert action.persisted?
    assert_equal @article, action.target
    assert_equal "Article", action.target_type
  end

  test "persists with nil user (optional user association)" do
    action = Action.create!(
      action_type: "upvote",
      target: @author,
      target_type: "User"
    )

    assert action.persisted?
    assert_nil action.user
  end

  test "persists with nil target (optional target association)" do
    action = Action.create!(
      action_type: "block",
      user: @subscriber,
      user_type: "User"
    )

    assert action.persisted?
    assert_nil action.target
  end

  # ---------------------------------------------------------------- notifications association

  test "#notifications returns the noticed_events association" do
    action = Action.create!(
      action_type: "subscribe",
      user: @subscriber,
      user_type: "User",
      target: @author,
      target_type: "User"
    )

    assert_equal action.noticed_events, action.notifications
    assert_empty action.notifications
  end

  # ---------------------------------------------------------------- destroy cascade

  test "destroy cascades to noticed_events" do
    action = Action.create!(
      action_type: "subscribe",
      user: @subscriber,
      user_type: "User",
      target: @author,
      target_type: "User"
    )

    deliver_notifier!(
      SubscribeUserActionCreatedNotifier,
      record: action,
      action: action,
      recipient: @author
    )

    assert_equal 1, action.noticed_events.count

    assert_difference -> { Noticed::Event.where(record: action).count }, -1 do
      action.destroy!
    end
  end

  test "destroy_notifications rescues StandardError and logs instead of raising" do
    action = Action.create!(
      action_type: "subscribe",
      user: @subscriber,
      user_type: "User",
      target: @author,
      target_type: "User"
    )

    logger = Rails.logger
    log_output = StringIO.new
    Rails.logger = Logger.new(log_output)
    begin
      relation = action.noticed_events
      relation.define_singleton_method(:destroy_all) { raise StandardError, "boom" }

      # Should not raise.
      action.send(:destroy_notifications)

      assert_match(/Failed to destroy notifications for action #{action.id}/, log_output.string)
    ensure
      Rails.logger = logger
    end
  end

  # ---------------------------------------------------------------- notify_target dispatch

  # The remaining tests turn the after_create :notify_target callback back on
  # so we can verify which (action_type, target_type) pairs trigger the
  # SubscribeUserActionCreatedNotifier. We assert against
  # SubscribeUserActionCreatedNotifier.with(...).deliver(recipient) directly so
  # we don't depend on the full Noticed::Event + MixinBot delivery chain.
  test "notify_target delivers SubscribeUserActionCreatedNotifier for :subscribe + User target" do
    Action.set_callback :create, :after, :notify_target

    delivered_with = nil
    delivered_to = nil
    SubscribeUserActionCreatedNotifier.singleton_class.define_method(:with) do |params|
      delivered_with = params
      _ = delivered_to
      notification = Object.new
      notification.define_singleton_method(:deliver) do |recipient|
        delivered_to = recipient
        true
      end
      notification
    end

    begin
      Action.create!(
        action_type: "subscribe",
        user: @subscriber,
        user_type: "User",
        target: @author,
        target_type: "User"
      )
    ensure
      SubscribeUserActionCreatedNotifier.singleton_class.send(:remove_method, :with)
      SubscribeUserActionCreatedNotifier.singleton_class.define_method(:with, SubscribeUserActionCreatedNotifier.method(:with))
    end

    assert_equal @author, delivered_to
    assert_equal :subscribe, delivered_with[:action].action_type.to_sym
    assert_equal @subscriber, delivered_with[:action].user
  end

  test "notify_target is a no-op for :subscribe when target is not a User" do
    skip "fixture articles(:published_paid) not present" unless @article

    Action.set_callback :create, :after, :notify_target

    delivered = false
    SubscribeUserActionCreatedNotifier.singleton_class.define_method(:with) do |*_args|
      delivered = true
      notification = Object.new
      notification.define_singleton_method(:deliver) { |*_args| true }
      notification
    end

    begin
      Action.create!(
        action_type: "subscribe",
        user: @subscriber,
        user_type: "User",
        target: @article,
        target_type: "Article"
      )
    ensure
      SubscribeUserActionCreatedNotifier.singleton_class.send(:remove_method, :with)
      SubscribeUserActionCreatedNotifier.singleton_class.define_method(:with, SubscribeUserActionCreatedNotifier.method(:with))
    end

    assert_not delivered
  end

  test "notify_target is a no-op for non-subscribe action_types" do
    Action.set_callback :create, :after, :notify_target

    delivered = false
    SubscribeUserActionCreatedNotifier.singleton_class.define_method(:with) do |*_args|
      delivered = true
      notification = Object.new
      notification.define_singleton_method(:deliver) { |*_args| true }
      notification
    end

    begin
      Action.create!(
        action_type: "block",
        user: @subscriber,
        user_type: "User",
        target: @author,
        target_type: "User"
      )
    ensure
      SubscribeUserActionCreatedNotifier.singleton_class.send(:remove_method, :with)
      SubscribeUserActionCreatedNotifier.singleton_class.define_method(:with, SubscribeUserActionCreatedNotifier.method(:with))
    end

    assert_not delivered
  end

  test "notify_target is a no-op when target is nil" do
    Action.set_callback :create, :after, :notify_target

    delivered = false
    SubscribeUserActionCreatedNotifier.singleton_class.define_method(:with) do |*_args|
      delivered = true
      notification = Object.new
      notification.define_singleton_method(:deliver) { |*_args| true }
      notification
    end

    begin
      Action.create!(
        action_type: "subscribe",
        user: @subscriber,
        user_type: "User"
      )
    ensure
      SubscribeUserActionCreatedNotifier.singleton_class.send(:remove_method, :with)
      SubscribeUserActionCreatedNotifier.singleton_class.define_method(:with, SubscribeUserActionCreatedNotifier.method(:with))
    end

    assert_not delivered
  end
end
