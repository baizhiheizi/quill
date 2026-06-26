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
#  comment_created    :jsonb
#  tagging_created    :jsonb
#  transfer_processed :jsonb
#  webhook            :jsonb
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
  CATEGORIES = %i[article_published article_bought article_rewarded comment_created tagging_created transfer_processed].freeze
  CHANNELS = %i[web mixin_bot webhook].freeze

  test "DEFAULT_SETTING is frozen" do
    assert_predicate NotificationSetting::DEFAULT_SETTING, :frozen?
  end

  test "DEFAULT_SETTING covers every channel for every category" do
    CATEGORIES.each do |category|
      CHANNELS.each do |channel|
        key = :"#{category}_#{channel}"
        assert NotificationSetting::DEFAULT_SETTING.key?(key),
          "DEFAULT_SETTING missing #{key}"
      end
    end
  end

  test "DEFAULT_SETTING enables web and mixin_bot delivery by default and webhook off" do
    CATEGORIES.each do |category|
      CHANNELS.each do |channel|
        key = :"#{category}_#{channel}"
        expected = channel == :webhook ? false : true
        assert_equal expected, NotificationSetting::DEFAULT_SETTING[key],
          "DEFAULT_SETTING[#{key}] expected #{expected}"
      end
    end
  end

  test "DEFAULT_SETTING webhook_url defaults to nil" do
    assert_nil NotificationSetting::DEFAULT_SETTING[:webhook_url]
  end

  test "set_defaults applies DEFAULT_SETTING to a new record" do
    setting = NotificationSetting.new(user: users(:reader_one))

    CATEGORIES.each do |category|
      CHANNELS.each do |channel|
        assert_equal NotificationSetting::DEFAULT_SETTING[:"#{category}_#{channel}"],
          setting.public_send(:"#{category}_#{channel}")
      end
    end
    assert_nil setting.webhook_url
  end

  test "set_defaults overwrites user-supplied attributes on a new record" do
    # `after_initialize set_defaults` runs after constructor attribute assignment,
    # so custom values passed to `.new` are silently replaced.
    setting = NotificationSetting.new(
      user: users(:reader_two),
      webhook_url: "https://example.com/hook",
      article_published_web: false
    )

    assert_nil setting.webhook_url
    assert_equal true, setting.article_published_web
  end

  test "set_defaults does not re-fire on update" do
    user = users(:reader_one)
    user.create_notification_setting! if user.notification_setting.blank?
    setting = user.notification_setting

    setting.update!(webhook_url: "https://example.com/hook", article_published_web: false)

    assert_equal "https://example.com/hook", setting.reload.webhook_url
    assert_equal false, setting.reload.article_published_web
  end

  test "cast_string_value_to_boolean coerces the standard string falsey / truthy values" do
    user = users(:reader_one)
    user.create_notification_setting! if user.notification_setting.blank?
    setting = user.notification_setting

    # `set_defaults` would overwrite constructor-supplied attrs on a new record,
    # so update! the existing record and let `before_validation` cast the strings.
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

  test "cast_string_value_to_boolean leaves already-coerced true / false untouched" do
    user = users(:reader_one)
    user.create_notification_setting! if user.notification_setting.blank?
    setting = user.notification_setting

    setting.update!(article_published_web: true, transfer_processed_web: false)

    assert_equal true, setting.reload.article_published_web
    assert_equal false, setting.reload.transfer_processed_web
  end

  test "cast_string_value_to_boolean runs on update as well" do
    user = users(:reader_one)
    user.create_notification_setting! if user.notification_setting.blank?
    setting = user.notification_setting

    # Bypass set_defaults by skipping after_initialize on the next record;
    # `update!` triggers the `before_validation` cast callback regardless.
    setting.update!(article_published_web: "false", article_bought_web: "1")

    assert_equal false, setting.reload.article_published_web
    assert_equal true, setting.reload.article_bought_web
  end

  test "reset restores DEFAULT_SETTING on an existing record" do
    user = users(:reader_one)
    user.create_notification_setting! if user.notification_setting.blank?
    setting = user.notification_setting

    # Dirty every default-bearing column to ensure `reset` actually rewrites them.
    setting.update!(
      webhook_url: "https://example.com/x",
      article_published_web: false,
      article_published_mixin_bot: false,
      article_published_webhook: true,
      comment_created_web: false,
      transfer_processed_webhook: true
    )

    setting.reset
    setting.reload

    CATEGORIES.each do |category|
      CHANNELS.each do |channel|
        assert_equal NotificationSetting::DEFAULT_SETTING[:"#{category}_#{channel}"],
          setting.public_send(:"#{category}_#{channel}"),
          "reset failed for #{category}_#{channel}"
      end
    end
    assert_nil setting.webhook_url
  end

  test "webhook_url accessor roundtrips through the webhook jsonb store" do
    user = users(:reader_one)
    user.create_notification_setting! if user.notification_setting.blank?
    setting = user.notification_setting

    setting.update!(webhook_url: "https://example.com/hook")

    assert_equal "https://example.com/hook", setting.reload.webhook_url
    assert_equal "https://example.com/hook", setting.reload.webhook["url"]
  end

  test "article_bought_daily_times accessor is exposed even though DEFAULT_SETTING omits it" do
    user = users(:reader_one)
    user.create_notification_setting! if user.notification_setting.blank?
    setting = user.notification_setting

    setting.update!(article_bought_daily_times: 7)

    assert_equal 7, setting.reload.article_bought_daily_times
    assert_equal 7, setting.reload.article_bought["daily_times"]
    assert_nil NotificationSetting::DEFAULT_SETTING[:article_bought_daily_times]
  end

  test "User#create_notification_setting! builds a setting with defaults applied" do
    user = users(:reader_two)
    user.notification_setting&.destroy!
    assert_nil user.reload.notification_setting

    setting = user.create_notification_setting!

    assert_equal user, setting.user
    assert_equal true, setting.article_published_web
    assert_equal true, setting.transfer_processed_mixin_bot
    assert_equal false, setting.comment_created_webhook
    assert_nil setting.webhook_url
  end
end
