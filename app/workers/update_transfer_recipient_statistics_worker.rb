# frozen_string_literal: true

class UpdateTransferRecipientStatisticsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :low, retry: false

  def perform(trace_id)
    Transfer.find_by(trace_id: trace_id)&.update_recipient_statistics_cache
  end
end
