# frozen_string_literal: true

class Articles::UploadToArweaveJob < ApplicationJob
  queue_as :default
  def perform(id)
    Article.find(id)&.upload_to_arweave!
  end
end
