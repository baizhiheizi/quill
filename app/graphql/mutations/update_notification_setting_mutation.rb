# frozen_string_literal: true

module Mutations
  class UpdateNotificationSettingMutation < Mutations::BaseMutation
    argument :webhook_url, String, required: false
    argument :article_published_web, Boolean, required: false
    argument :article_published_mixin_bot, Boolean, required: false
    argument :article_published_webhook, Boolean, required: false
    argument :article_bought_web, Boolean, required: false
    argument :article_bought_mixin_bot, Boolean, required: false
    argument :article_bought_webhook, Boolean, required: false
    argument :article_rewarded_web, Boolean, required: false
    argument :article_rewarded_mixin_bot, Boolean, required: false
    argument :article_rewarded_webhook, Boolean, required: false
    argument :comment_created_web, Boolean, required: false
    argument :comment_created_mixin_bot, Boolean, required: false
    argument :comment_created_webhook, Boolean, required: false
    argument :tagging_created_web, Boolean, required: false
    argument :tagging_created_mixin_bot, Boolean, required: false
    argument :tagging_created_webhook, Boolean, required: false
    argument :transfer_processed_web, Boolean, required: false
    argument :transfer_processed_mixin_bot, Boolean, required: false
    argument :transfer_processed_webhook, Boolean, required: false

    type Types::NotificationSettingType

    def resolve(params)
      current_user.notification_setting.update params
      current_user.notification_setting.reload
    end
  end
end
