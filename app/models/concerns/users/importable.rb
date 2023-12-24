# frozen_string_literal: true

module Users::Importable
  extend ActiveSupport::Concern

  def import_articles_from_mirror_async
    Users::ImportArticlesFromMirrorJob.perform_later id
  end

  def import_articles_from_mirror
    return unless mvm_eth?
    return if Rails.cache.fetch "_#{uid}_importing_from_mirror_lock"

    Rails.cache.write "_#{uid}_importing_from_mirror_lock", true, expires_in: 5.minutes

    txs = ArweaveBot.graphql.all_mirror_transactions uid

    txs.each do |tx|
      uuid = Digest::MD5.hexdigest tx[:digest]
      next if Article.exists? uuid: uuid

      r = ArweaveBot.api.transaction tx[:id]
      article = articles.create_with(
        title: r['content']['title'],
        content: r['content']['body'],
        price: 0
      ).find_or_create_by(uuid: uuid)

      ArticleImportedNotification.with(article: article).deliver(self) if article.persisted?
    end
  ensure
    Rails.cache.delete "_#{uid}_importing_from_mirror_lock"
  end
end
