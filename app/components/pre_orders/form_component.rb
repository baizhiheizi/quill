# frozen_string_literal: true

class PreOrders::FormComponent < ApplicationComponent
  def initialize(pre_order:, payer:)
    super

    @payer = payer
    @pre_order = pre_order
    @article = pre_order.item
    @price =
      case pre_order.order_type
      when 'reward_article'
        @article.currency.minimal_reward_amount
      when 'buy_article'
        @article.price
      end
  end
end
