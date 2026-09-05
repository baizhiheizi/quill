# frozen_string_literal: true

# == Schema Information
#
# Table name: notification_settings
# Database name: primary
#
#  id                 :bigint           not null, primary key
#  article_bought     :jsonb
#  article_published  :jsonb
#  article_rewarded   :jsonb
#  collection_bought  :jsonb
#  collection_listed  :jsonb
#  comment_created    :jsonb
#  tagging_created    :jsonb
#  transfer_processed :jsonb
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  user_id            :bigint
#
# Indexes
#
#  index_notification_settings_on_user_id  (user_id)
#

require "test_helper"

class NotificationSettingTest < ActiveSupport::TestCase
  setup do
    @user = users(:reader_one)
  end

  test "DEFAULT_SETTING is frozen" do
    assert_predicate NotificationSetting::DEFAULT_SETTING, :frozen?
  end

  test "DEFAULT_SETTING is derived from the kind registry" do
    assert_equal NotificationKind.settings_defaults, NotificationSetting::DEFAULT_SETTING
  end

  test "DEFAULT_SETTING enables both channels for every muteable kind" do
    NotificationKind.with_settings.each do |kind|
      NotificationKind::CHANNELS.each do |channel|
        assert_equal true, NotificationSetting::DEFAULT_SETTING[kind.setting_key(channel)],
                     "DEFAULT_SETTING[#{kind.setting_key(channel)}] should default to on"
      end
    end
  end

  test "no store is declared for the dead webhook channel" do
    assert_empty NotificationSetting.column_names.grep(/webhook/)

    NotificationSetting::DEFAULT_SETTING.each_key do |key|
      assert_not_includes key.to_s, "webhook"
    end
  end

  test "set_defaults applies DEFAULT_SETTING to a new record" do
    setting = NotificationSetting.new(user: @user)

    NotificationKind.with_settings.each do |kind|
      NotificationKind::CHANNELS.each do |channel|
        assert_equal true, setting.public_send(kind.setting_key(channel)),
                     "#{kind.setting_key(channel)} should default to on"
      end
    end
  end

  test "set_defaults overwrites user-supplied attributes on a new record" do
    # `after_initialize set_defaults` runs after constructor attribute assignment,
    # so custom values passed to `.new` are silently replaced.
    setting = NotificationSetting.new(user: users(:reader_two), article_published_web: false)

    assert_equal true, setting.article_published_web
  end

  test "set_defaults does not re-fire on update" do
    setting = ensure_notification_setting!(@user)

    setting.update! article_published_web: false

    assert_equal false, setting.reload.article_published_web
  end

  test "a stored row missing a key reads as the declared default, not as muted" do
    setting = ensure_notification_setting!(@user)

    setting.update_columns article_published: {}, collection_bought: {}

    assert_equal true, setting.reload.article_published_web
    assert_equal true, setting.article_published_mixin_bot
    assert_equal true, setting.collection_bought_web
  end

  test "a stored row with an explicit false is not mistaken for a missing key" do
    setting = ensure_notification_setting!(@user)

    setting.update! article_published_web: false

    assert_equal false, setting.reload.article_published_web
  end

  test "cast_string_values_to_boolean coerces the standard string falsey / truthy values" do
    setting = ensure_notification_setting!(@user)

    setting.update!(
      article_published_web: "false",
      article_bought_web: "FALSE",
      comment_created_web: "true",
      article_rewarded_web: "1"
    )

    assert_equal false, setting.reload.article_published_web
    assert_equal false, setting.reload.article_bought_web
    assert_equal true, setting.reload.comment_created_web
    assert_equal true, setting.reload.article_rewarded_web
  end

  test "cast_string_values_to_boolean leaves already-coerced true / false untouched" do
    setting = ensure_notification_setting!(@user)

    setting.update! article_published_web: true, transfer_processed_web: false

    assert_equal true, setting.reload.article_published_web
    assert_equal false, setting.reload.transfer_processed_web
  end

  test "reset restores DEFAULT_SETTING on an existing record" do
    setting = ensure_notification_setting!(@user)

    # Dirty every default-bearing column to ensure `reset` actually rewrites them.
    setting.update!(
      article_published_web: false,
      article_published_mixin_bot: false,
      comment_created_web: false,
      collection_listed_web: false
    )

    setting.reset
    setting.reload

    NotificationKind.with_settings.each do |kind|
      NotificationKind::CHANNELS.each do |channel|
        assert_equal true, setting.public_send(kind.setting_key(channel)),
                     "reset failed for #{kind.setting_key(channel)}"
      end
    end
  end

  test "permittable settings are exactly the registry's toggles" do
    assert_equal NotificationKind.permittable_settings, NotificationSetting.permittable_settings
    assert NotificationSetting.permittable_settings.include?(:collection_bought_mixin_bot)
  end

  test "User#create_notification_setting! builds a setting with defaults applied" do
    user = users(:reader_two)
    user.notification_setting&.destroy!
    assert_nil user.reload.notification_setting

    setting = user.create_notification_setting!

    assert_equal user, setting.user
    assert_equal true, setting.article_published_web
    assert_equal true, setting.transfer_processed_mixin_bot
    assert_equal true, setting.collection_listed_web
  end
end
