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
class FennecPreOrder < PreOrder
  validate :ensure_payer_fennec

  private

  def ensure_payer_fennec
    errors.add(:payer, 'must from Fennec') unless payer.fennec?
  end
end
