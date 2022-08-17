# frozen_string_literal: true

class PreOrders::StateComponent < ApplicationComponent
  def initialize(pre_order:)
    super

    @pre_order = pre_order
  end
end
