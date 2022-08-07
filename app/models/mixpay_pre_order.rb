# frozen_string_literal: true

# == Schema Information
#
# Table name: pre_orders
#
#  id         :bigint           not null, primary key
#  amount     :decimal(, )
#  item_type  :string
#  memo       :string
#  order_type :string
#  state      :string
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  asset_id   :uuid
#  follow_id  :uuid
#  item_id    :bigint
#  payee_id   :uuid
#  payer_id   :uuid
#  trace_id   :uuid
#
# Indexes
#
#  index_pre_orders_on_item      (item_type,item_id)
#  index_pre_orders_on_payee_id  (payee_id)
#  index_pre_orders_on_payer_id  (payer_id)
#
class MixpayPreOrder < PreOrder
  validate :ensure_mixpay_supported

  def pay_url
    Addressable::URI.new(
      scheme: 'https',
      host: 'mixpay.me',
      path: 'pay',
      query_values: [
        ['payeeId', payee_id],
        ['settlementAssetId', asset_id],
        ['quoteAssetId', asset_id],
        ['quoteAmount', amount],
        ['traceId', trace_id],
        ['settlementMemo', memo],
        ['returnTo', pre_order_url(follow_id)]
      ]
    ).to_s
  end

  private

  def ensure_mixpay_supported
    errors.add(:item, 'not supported') unless item.mixpay_supported?
  end
end
