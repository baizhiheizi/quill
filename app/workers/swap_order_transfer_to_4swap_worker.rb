# frozen_string_literal: true

class SwapOrderTransferTo4swapWorker
  include Sidekiq::Worker
  sidekiq_options queue: :critical, retry: true

  def perform(id)
    SwapOrder.find_by(id: id)&.transfer_to_4swap!
  end
end
