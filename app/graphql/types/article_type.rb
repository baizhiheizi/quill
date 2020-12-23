# frozen_string_literal: true

module Types
  class ArticleType < BaseObject
    field :uuid, ID, null: false
    field :id, ID, null: false
    field :title, String, null: false
    field :intro, String, null: false
    field :content, String, null: true
    field :state, String, null: true
    field :asset_id, String, null: false
    field :price, Float, null: false

    field :revenue, Float, null: false
    field :author_revenue_amount, Float, null: false
    field :reader_revenue_amount, Float, null: false

    field :words_count, Integer, null: false
    field :partial_content, String, null: true

    field :orders_count, Integer, null: false
    field :comments_count, Integer, null: false
    field :upvotes_count, Integer, null: false
    field :downvotes_count, Integer, null: false
    field :upvote_ratio, Integer, null: true

    field :authorized, Boolean, null: true
    field :commenting_subscribed, Boolean, null: true
    field :upvoted, Boolean, null: true
    field :downvoted, Boolean, null: true

    field :my_share, Float, null: true
    field :payment_trace_id, String, null: true
    field :wallet_id, String, null: true

    field :author, Types::UserType, null: false
    field :wallet, Types::MixinNetworkUserType, null: true

    field :readers, Types::UserConnectionType, null: false
    field :buyers, Types::UserConnectionType, null: false
    field :rewarders, Types::UserConnectionType, null: false
    field :buy_orders, Types::OrderConnectionType, null: false
    field :reward_orders, Types::OrderConnectionType, null: false
    field :comments, Types::CommentConnectionType, null: false

    def content
      return unless object.authorized?(context[:current_user])

      object.content
    end

    def authorized
      object.authorized?(context[:current_user])
    end

    def commenting_subscribed
      context[:current_user]&.commenting_subscribe_article?(object)
    end

    def upvote_ratio
      return if object.upvotes_count + object.downvotes_count < 1

      (object.upvotes_count.to_f / (object.upvotes_count + object.downvotes_count) * 100).to_i
    end

    def upvoted
      context[:current_user]&.upvote_article?(object)
    end

    def downvoted
      context[:current_user]&.downvote_article?(object)
    end

    def my_share
      return unless object.authorized?(context[:current_user])

      object.share_of(context[:current_user])
    end

    def payment_trace_id
      return if context[:current_user].blank?
      return if authorized

      # generate a unique trace ID for paying
      # avoid duplicate payment
      candidate = PrsdiggBot.api.unique_conversation_id(object.uuid, context[:current_user].mixin_uuid)
      loop do
        break unless Payment.exists?(trace_id: candidate, state: %i[refunded completed])

        candidate = PrsdiggBot.api.unique_conversation_id(object.uuid, candidate)
      end

      candidate
    end

    def author
      BatchLoader::GraphQL.for(object.author_id).batch do |author_ids, loader|
        User.where(id: author_ids).each { |author| loader.call(author.id, author) }
      end
    end

    def wallet
      BatchLoader::GraphQL.for(object.id).batch do |ids, loader|
        MixinNetworkUser.where(owner_id: ids, owner_type: 'Article').each { |wallet| loader.call(wallet.owner_id, wallet) }
      end
    end
  end
end
