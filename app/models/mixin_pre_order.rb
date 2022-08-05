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
#  result     :json
#  state      :string
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  asset_id   :uuid
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
class MixinPreOrder < PreOrder
  validate :ensure_payer_mixin

  def pay_url
    Addressable::URI.new(
      scheme: 'mixin',
      host: 'pay',
      path: '',
      query_values: [
        ['recipient', payee_id],
        ['trace', trace_id],
        ['memo', memo],
        ['asset', asset_id],
        ['amount', amount.to_r.to_f]
      ]
    ).to_s
  end

  private

  def ensure_payer_mixin
    errors.add(:payer, 'must from Mixin') unless payer.messenger?
  end
end
