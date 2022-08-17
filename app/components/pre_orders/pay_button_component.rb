# frozen_string_literal: true

class PreOrders::PayButtonComponent < ApplicationComponent
  def initialize(pre_order:, pay_asset:)
    super

    @pre_order = pre_order
    @pay_asset = pay_asset || pre_order.currency
    @pay_amount = pre_order.pay_amount(@pay_asset.asset_id)
  end
end
