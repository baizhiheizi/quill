# frozen_string_literal: true

require "test_helper"

class ApplicationNotifierTest < ActiveSupport::TestCase
  test "persist_web_notification defaults to true" do
    assert ApplicationNotifier.persist_web_notification
  end

  test "mixin-only notifiers opt out of web persistence" do
    assert_not UserConnectedNotifier.persist_web_notification
    assert_not UserSafeRegistrationNotifier.persist_web_notification
  end
end
