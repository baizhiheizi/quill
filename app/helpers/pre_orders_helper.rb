# frozen_string_literal: true

module PreOrdersHelper
  def pre_order_form_price(pre_order)
    article = pre_order.item

    case pre_order.order_type
    when "reward_article"
      article.currency.minimal_reward_amount
    when "buy_article"
      article.price
    end
  end
end
