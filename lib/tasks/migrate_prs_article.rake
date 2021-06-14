# frozen_string_literal: true

task migrate_prs_article: :environment do
  Article.where(asset_id: Currency::PRS_ASSET_ID).each do |article|
    price = (article.price * 0.0258 / 39440).round(8)
    price = Article::MINIMUM_PRICE_BTC if price < Article::MINIMUM_PRICE_BTC
    article.update price: price, asset_id: Currency::BTC_ASSET_ID
  end
end
