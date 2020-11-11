# frozen_string_literal: true

module Types
  class UserType < Types::BaseObject
    field :id, Int, null: false
    field :name, String, null: false
    field :mixin_id, String, null: false
    field :mixin_uuid, String, null: false
    field :avatar_url, String, null: false
    field :bio, String, null: true

    field :articles_count, Int, null: false
    field :comments_count, Int, null: false
    field :author_revenue_amount, Float, null: false
    field :reader_revenue_amount, Float, null: false
    field :payments_total, Float, null: false

    field :authoring_subscribed, Boolean, null: true
    field :reading_subscribed, Boolean, null: true

    field :articles, Types::ArticleConnectionType, null: false
    field :comments, Types::CommentConnectionType, null: false

    def articles_count
      object.articles.count
    end

    def comments_count
      object.comments.count
    end

    def author_revenue_amount
      object.author_revenue_transfers.sum(:amount)
    end

    def reader_revenue_amount
      object.reader_revenue_transfers.sum(:amount)
    end

    def payments_total
      object.payments.completed.sum(:amount)
    end

    def authoring_subscribed
      context[:current_user]&.authoring_subscribe_user?(object)
    end

    def reading_subscribed
      context[:current_user]&.reading_subscribe_user?(object)
    end
  end
end
