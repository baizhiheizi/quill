# frozen_string_literal: true

class Articles::UploadToArweaveJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: true

  def perform(id)
    Article.find(id)&.upload_to_arweave!
  end
end
