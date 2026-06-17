# frozen_string_literal: true

json.array! @articles do |article|
  json.id article.id
  json.title article.title
  json.author do
    json.name article.author.name
    json.avatar article.author.avatar_image_url
    json.avatar_seed article.author.mixin_uuid
    json.avatar_initials avatar_initials(article.author.name)
  end
end
