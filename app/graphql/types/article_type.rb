# frozen_string_literal: true

module Types
  class ArticleType < BaseObject
    field :uuid, ID, null: false
    field :id, ID, null: false
    field :title, String, null: true
    field :intro, String, null: true
    field :content, String, null: true
    field :state, String, null: true
    field :asset_id, String, null: false
    field :price, Float, null: false
    field :price_usd, Float, null: true
    field :published_at, GraphQL::Types::ISO8601DateTime, null: true

    field :tags_count, Int, null: false
    field :tag_names, [String], null: true

    field :author_revenue_ratio, Float, null: false
    field :readers_revenue_ratio, Float, null: false
    field :platform_revenue_ratio, Float, null: false
    field :references_revenue_ratio, Float, null: false

    field :revenue_usd, Float, null: false
    field :revenue_btc, Float, null: false
    field :author_revenue_usd, Float, null: false
    field :reader_revenue_usd, Float, null: false

    field :words_count, Integer, null: false
    field :partial_content, String, null: true

    field :orders_count, Integer, null: false
    field :comments_count, Integer, null: false
    field :upvotes_count, Integer, null: false
    field :downvotes_count, Integer, null: false
    field :upvote_ratio, Integer, null: true

    field :authorized, Boolean, null: true
    field :swappable, Boolean, null: true
    field :commenting_subscribed, Boolean, null: true
    field :upvoted, Boolean, null: true
    field :downvoted, Boolean, null: true

    field :my_share, Float, null: true
    field :payment_trace_id, String, null: true
    field :wallet_id, String, null: true

    field :currency, Types::CurrencyType, null: false
    field :signature_url, String, null: true

    field :author, Types::UserType, null: false
    field :wallet, Types::MixinNetworkUserType, null: true

    field :readers, Types::UserConnectionType, null: false
    field :buyers, Types::UserConnectionType, null: false
    field :rewarders, Types::UserConnectionType, null: false

    field :buy_orders, Types::OrderConnectionType, null: false
    field :reward_orders, Types::OrderConnectionType, null: false
    field :comments, Types::CommentConnectionType, null: false

    field :random_readers, [UserType], null: false
    field :tags, [Types::TagType], null: false
    field :citers, [Types::ArticleType], null: true
    field :references, [Types::ArticleType], null: true
    field :article_references, [Types::CiterReferenceType], null: true

    def content
      return unless object.authorized?(context[:current_user])

      object.content.to_s.strip
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

    def swappable
      object.swappable?
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

    def tags
      BatchLoader::GraphQL.for(object.id).batch(default_value: []) do |ids, loader|
        Tagging.includes(:tag).where(article_id: ids).each do |tagging|
          loader.call(tagging.article_id) { |memo| memo << tagging.tag }
        end
      end
    end

    def currency
      BatchLoader::GraphQL.for(object.asset_id).batch do |asset_ids, loader|
        Currency.where(asset_id: asset_ids).each { |currency| loader.call(currency.asset_id, currency) }
      end
    end
  end
end
