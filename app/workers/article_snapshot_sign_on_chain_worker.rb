# frozen_string_literal: true

class ArticleSnapshotSignOnChainWorker
  include Sidekiq::Worker
  sidekiq_options queue: :pressone, retry: true

  def perform(id)
    ArticleSnapshot.find(id).sign_on_chain!
  end
end
