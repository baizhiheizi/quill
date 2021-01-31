# frozen_string_literal: true

module Types
  class NotificationSettingType < Types::BaseObject
    field :id, ID, null: false
    field :webhook_url, String, null: true
    field :article_published_web, Boolean, null: true
    field :article_published_mixin_bot, Boolean, null: true
    field :article_published_webhook, Boolean, null: true
    field :article_bought_web, Boolean, null: true
    field :article_bought_mixin_bot, Boolean, null: true
    field :article_bought_webhook, Boolean, null: true
    field :article_rewarded_web, Boolean, null: true
    field :article_rewarded_mixin_bot, Boolean, null: true
    field :article_rewarded_webhook, Boolean, null: true
    field :comment_created_web, Boolean, null: true
    field :comment_created_mixin_bot, Boolean, null: true
    field :comment_created_webhook, Boolean, null: true
    field :tagging_created_web, Boolean, null: true
    field :tagging_created_mixin_bot, Boolean, null: true
    field :tagging_created_webhook, Boolean, null: true
    field :transfer_processed_web, Boolean, null: true
    field :transfer_processed_mixin_bot, Boolean, null: true
    field :transfer_processed_webhook, Boolean, null: true

    field :user, Types::UserType, null: false
  end
end
