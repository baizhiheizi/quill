# frozen_string_literal: true

module Types
  class ArticleType < BaseObject
    field :uuid, ID, null: false
    field :title, String, null: false
    field :intro, String, null: false
    field :content, String, null: false
    field :asset_id, String, null: false
    field :price, Float, null: false

    field :author, Types::UserType, null: false
  end
end
