# frozen_string_literal: true

require "test_helper"

# Pins the contract every other notification file is generated from: one
# declaration per kind, one notifier per declaration.
class NotificationKindTest < ActiveSupport::TestCase
  test "every kind is declared by the notifier it names" do
    NotificationKind.all.each do |kind|
      notifier = kind.notifier.constantize

      assert_equal kind, notifier.notification_kind, "#{kind.notifier} must call `notifies :#{kind.name}`"
    end
  end

  test "every notifier file declares exactly one kind" do
    files = Rails.root.glob("app/notifiers/*_notifier.rb")
      .map { |path| File.basename(path, ".rb").camelize }
      .reject { |name| name == "ApplicationNotifier" }

    assert_equal files.sort, NotificationKind.all.map(&:notifier).sort
  end

  test "every kind renders as the category its notifier delivers with" do
    NotificationKind.all.each do |kind|
      expected = kind.card? ? "APP_CARD" : "PLAIN_TEXT"

      assert_equal expected, kind.mixin_category
    end
  end

  test "every muteable kind has a settings column and derives both toggles" do
    NotificationKind.with_settings.each do |kind|
      assert NotificationSetting.column_names.include?(kind.settings_key.to_s),
             "notification_settings is missing the #{kind.settings_key} column"

      NotificationKind::CHANNELS.each do |channel|
        key = kind.setting_key(channel)

        assert NotificationSetting::DEFAULT_SETTING[key], "#{key} should default to on"
        assert_includes NotificationSetting.permittable_settings, key, "#{key} should be permitted"
      end
    end
  end

  test "kinds without settings expose no toggles" do
    stray = NotificationKind.all.reject(&:settings?).flat_map do |kind|
      NotificationSetting::DEFAULT_SETTING.keys.select { |key| key.to_s.start_with?("#{kind.name}_") }
    end

    assert_empty stray, "kinds without settings must not declare toggles"
  end

  test "web visible notification types cover every kind that can reach the inbox" do
    types = NotificationKind.web_visible_notification_types

    assert_includes types, "ArticleBoughtNotifier::Notification"
    assert_not_includes types, "UserConnectedNotifier::Notification"
    assert_not_includes types, "UserSafeRegistrationNotifier::Notification"
    assert_equal NotificationKind.all.count(&:web?), types.size
  end

  test "settings form order is unique and covers every muteable kind" do
    positions = NotificationKind.with_settings.map(&:position)

    assert_equal positions.size, positions.uniq.size
    assert_equal NotificationKind.all.count(&:settings?), positions.size
  end
end
