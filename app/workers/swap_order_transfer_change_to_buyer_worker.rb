# frozen_string_literal: true

class SwapOrderTransferChangeToBuyerWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, retry: true

  def perform(id)
    SwapOrder.find_by(id: id)&.transfer_change_to_buyer!
  end
end
