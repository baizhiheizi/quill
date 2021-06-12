# frozen_string_literal: true

json.extract! @article, :uuid, :title, :partial_content, :intro, :price_usd, :tag_names, :state, :orders_count, :comments_count, :upvotes_count, :downvotes_count, :created_at, :updated_at
json.price @article.price.to_f
json.currency @article.currency.symbol
json.original_url format('%<host>s/articles/%<uuid>s', host: Settings.host, uuid: @article.uuid)
json.author do
  json.name @article.author.name
  json.avatar @article.author.avatar
end

json.content @article.content if @article.authorized?(current_user)
