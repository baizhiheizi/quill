# frozen_string_literal: true

class ArticleMarkAsRemovedOnChainWorker
  include Sidekiq::Worker
  sidekiq_options queue: :pressone, retry: true

  def perform(id)
    Article.find(id).mark_as_removed_on_chain!
  end
end
