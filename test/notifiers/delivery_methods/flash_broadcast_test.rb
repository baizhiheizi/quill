# frozen_string_literal: true

require "test_helper"

class DeliveryMethods::FlashBroadcastTest < ActiveSupport::TestCase
  test "deliver forwards to notification.broadcast_as_flash" do
    called = false
    notification = Object.new
    notification.define_singleton_method(:broadcast_as_flash) { called = true }

    delivery = DeliveryMethods::FlashBroadcast.new
    delivery.instance_variable_set(:@notification, notification)

    delivery.deliver

    assert called, "expected notification.broadcast_as_flash to be called"
  end
end
