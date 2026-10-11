# frozen_string_literal: true

# Shared purchase interface for anything that can be the `item` of an
# `Order` / `PreOrder` (`Article`, `Collection`). `PreOrder#setup_attributes`
# derives its trace from `item.payment_trace_id` and `MixpayPreOrder` gates
# on `item.mixpay_supported?`, so every purchasable item must answer both
# identically — the rules live here, not per model.
#
# Item-specific policy stays on the model: `Article#mixpay_supported?`
# short-circuits free articles via `super`, and `authorized?` /
# `may_buy_by?` are Article rules (Collections authorize differently).
module Purchasable
  extend ActiveSupport::Concern

  def payment_trace_id(user)
    return if user.blank?

    # generate a unique trace ID for paying
    # avoid duplicate payment
    candidate = QuillBot.api.unique_uuid(uuid, user.mixin_uuid)
    loop do
      break unless Payment.exists?(trace_id: candidate) || PreOrder.exists?(trace_id: candidate, state: %i[paid expired])

      candidate = QuillBot.api.unique_uuid(uuid, candidate)
    end

    candidate
  end

  def mixpay_supported?
    asset_id.in?(Mixpay.api.settlement_asset_ids)
  rescue Mixpay::Errors::Error
    false
  end
end
