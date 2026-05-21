# frozen_string_literal: true

module Articles::Purchasable
  extend ActiveSupport::Concern

  def may_buy_by?(user = nil)
    return false if author.block_user?(user)
    return false if user&.block_user?(author)

    published?
  end

  def authorized?(user = nil)
    return true if (published? && free?) || author == user
    return false if user.blank?

    orders.where(order_type: :buy_article).find_by(buyer: user).present? || collection&.authorized?(user)
  end
end
