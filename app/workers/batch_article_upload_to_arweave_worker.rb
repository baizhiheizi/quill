# frozen_string_literal: true

class BatchArticleUploadToArweaveWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: true

  def perform
    Article.where(updated_at: 1.hour.ago...).map(&:upload_to_arweave_async)
  end
end
