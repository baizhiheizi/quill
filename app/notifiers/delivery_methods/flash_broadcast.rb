# frozen_string_literal: true

class DeliveryMethods::FlashBroadcast < Noticed::DeliveryMethod
  def deliver
    notification.broadcast_as_flash
  end
end
