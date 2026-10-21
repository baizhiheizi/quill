# frozen_string_literal: true

module PreOrdersHelper
  def pre_order_form_price(pre_order)
    article = pre_order.item

    case pre_order.order_type
    when "reward_article"
      article.currency.minimal_reward_amount
    else
      # Buy pre-orders (`buy_article`, `buy_collection`) quote the item's own
      # price. Falling through to `nil` made the form call
      # `sprintf('%.8f', nil)` and raise, so every unsupported order type
      # 500'd instead of rendering.
      article.price
    end
  end
end
