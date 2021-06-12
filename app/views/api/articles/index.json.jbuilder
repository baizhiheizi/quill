# frozen_string_literal: true

json.array! @articles do |article|
  json.uuid article.uuid
  json.title article.title
  json.intro article.intro
  json.partial_content article.partial_content
  json.price_usd article.price_usd
  json.price article.price.to_f
  json.currency article.currency.symbol
  json.tag_names article.tag_names
  json.original_url format('%<host>s/articles/%<uuid>s', host: Settings.host, uuid: article.uuid)
  json.state article.state
  json.orders_count article.orders_count
  json.comments_count article.comments_count
  json.upvotes_count article.upvotes_count
  json.downvotes_count article.downvotes_count
  json.created_at article.created_at
  json.updated_at article.updated_at

  json.author do
    json.name article.author.name
    json.avatar article.author.avatar
  end
end
