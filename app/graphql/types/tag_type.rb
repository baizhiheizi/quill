# frozen_string_literal: true

module Types
  class TagType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: true
    field :articles_count, Int, null: true
    field :color, String, null: true
  end
end
