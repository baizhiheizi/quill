# frozen_string_literal: true

class BatchArticleUploadToArweaveWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: true

  def perform
    Article
      .published
      .where(updated_at: 1.hour.ago.beginning_of_hour...1.hour.ago.end_of_hour)
      .map(&:upload_to_arweave_async)
  end
end
