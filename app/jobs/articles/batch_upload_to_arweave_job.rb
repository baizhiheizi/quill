# frozen_string_literal: true

class Articles::BatchUploadToArweaveJob < ApplicationJob
  def perform
    Article
      .published
      .where(updated_at: 1.hour.ago.beginning_of_hour...1.hour.ago.end_of_hour)
      .map(&:upload_to_arweave_async)
  end
end
