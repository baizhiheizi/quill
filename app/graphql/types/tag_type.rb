# frozen_string_literal: true

module Types
  class TagType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: true
    field :articles_count, Int, null: false
    field :subscribers_count, Int, null: false
    field :color, String, null: true

    field :subscribed, Boolean, null: true

    def subscribed
      context[:current_user]&.subscribe_tag?(object)
    end
  end
end
