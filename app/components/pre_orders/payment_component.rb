# frozen_string_literal: true

class PreOrders::PaymentComponent < ApplicationComponent
  def initialize(pre_order:)
    super

    @pre_order = pre_order
    @pay_asset = pre_order.currency
    @identifier = SecureRandom.uuid
  end
end
