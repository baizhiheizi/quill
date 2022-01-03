# frozen_string_literal: true

class ArticleCreateWalletWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform(id)
    article = Article.find_by(id: id)
    return if article.blank?

    article.create_wallet! if article.wallet.blank?
  end
end
