# frozen_string_literal: true

class PreOrders::MixpayButtonComponent < ApplicationComponent
  def initialize(pre_order:)
    super

    @pre_order = pre_order
  end
end
