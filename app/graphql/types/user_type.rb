# frozen_string_literal: true

module Types
  class UserType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :mixin_id, ID, null: false
    field :mixin_uuid, String, null: false
    field :avatar_url, String, null: false
    field :bio, String, null: true
    field :banned_at, GraphQL::Types::ISO8601DateTime, null: true

    field :statistics, UserStatisticsType, null: false

    field :authoring_subscribed, Boolean, null: true
    field :reading_subscribed, Boolean, null: true

    field :articles, Types::ArticleConnectionType, null: false
    field :comments, Types::CommentConnectionType, null: false

    def authoring_subscribed
      context[:current_user]&.authoring_subscribe_user?(object)
    end

    def reading_subscribed
      context[:current_user]&.reading_subscribe_user?(object)
    end

    def articles
      BatchLoader::GraphQL.for(object.id).batch(default_value: []) do |ids, loader|
        Article.where(author_id: ids).each do |article|
          loader.call(article.author_id) { |articles| articles << article }
        end
      end
    end

    def comments
      BatchLoader::GraphQL.for(object.id).batch(default_value: []) do |ids, loader|
        Comment.where(author_id: ids).each do |comment|
          loader.call(comment.author_id) { |comments| comments << comment }
        end
      end
    end

    def author_revenue_transfers
      BatchLoader::GraphQL.for(object.mixin_uuid).batch(default_value: []) do |uuids, loader|
        Transfer.where(transfer_type: :reader_revenue, opponent_id: uuids).each do |transfer|
          loader.call(transfer.opponent_id) { |transfers| transfers << transfer }
        end
      end
    end

    def reader_revenue_transfers
      BatchLoader::GraphQL.for(object.mixin_uuid).batch(default_value: []) do |uuids, loader|
        Transfer.where(transfer_type: :reader_revenue, opponent_id: uuids).each do |transfer|
          loader.call(transfer.opponent_id) { |transfers| transfers << transfer }
        end
      end
    end

    def revenue_transfers
      BatchLoader::GraphQL.for(object.mixin_uuid).batch(default_value: []) do |uuids, loader|
        Transfer.where(transfer_type: %w[author_revenue reader_revenue], opponent_id: uuids).each do |transfer|
          loader.call(transfer.opponent_id) { |transfers| transfers << transfer }
        end
      end
    end
  end
end
