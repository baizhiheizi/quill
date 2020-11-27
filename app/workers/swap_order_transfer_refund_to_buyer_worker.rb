# frozen_string_literal: true

class SwapOrderTransferRefundToBuyerWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, retry: true

  def perform(id)
    SwapOrder.find_by(id: id)&.transfer_refund_to_buyer!
  end
end
