# frozen_string_literal: true

module Users::Importable
  extend ActiveSupport::Concern

  def import_articles_from_mirror_async
    UserImportArticlesFromMirrorWorker.perform_async id
  end

  def import_articles_from_mirror
    return unless mvm_eth?

    txs = ArweaveBot.graphql.all_mirror_transactions uid

    txs.each do |tx|
      uuid = Digest::MD5.hexdigest tx[:digest]
      next if Article.exists? uuid: uuid

      r = ArweaveBot.api.transaction tx[:id]
      articles.create_with(
        author: author,
        title: r['content']['title'],
        content: r['content']['body'],
        price: 0
      ).find_or_create_by(uuid: uuid)
    end
  end
end
