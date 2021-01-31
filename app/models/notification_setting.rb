# frozen_string_literal: true

# == Schema Information
#
# Table name: notification_settings
#
#  id                 :bigint           not null, primary key
#  article_bought     :jsonb
#  article_published  :jsonb
#  article_rewarded   :jsonb
#  comment_created    :jsonb
#  tagging_created    :jsonb
#  transfer_processed :jsonb
#  webhook            :jsonb
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  user_id            :bigint
#
# Indexes
#
#  index_notification_settings_on_user_id  (user_id)
#
class NotificationSetting < ApplicationRecord
  DEFAULT_SETTING = {
    webhook_url: nil,
    article_published_web: true,
    article_published_mixin_bot: true,
    article_published_webhook: false,
    article_bought_web: true,
    article_bought_mixin_bot: true,
    article_bought_webhook: false,
    article_rewarded_web: true,
    article_rewarded_mixin_bot: true,
    article_rewarded_webhook: false,
    comment_created_web: true,
    comment_created_mixin_bot: true,
    comment_created_webhook: false,
    tagging_created_web: true,
    tagging_created_mixin_bot: true,
    tagging_created_webhook: false,
    transfer_processed_web: true,
    transfer_processed_mixin_bot: true,
    transfer_processed_webhook: false
  }.freeze

  store :webhook, accessors: %i[url], prefix: true
  store :article_published, accessors: %i[web mixin_bot webhook], prefix: true
  store :article_bought, accessors: %i[web mixin_bot webhook daily_times], prefix: true
  store :article_rewarded, accessors: %i[web mixin_bot webhook daily_times], prefix: true
  store :comment_created, accessors: %i[web mixin_bot webhook], prefix: true
  store :tagging_created, accessors: %i[web mixin_bot webhook], prefix: true
  store :transfer_processed, accessors: %i[web mixin_bot webhook], prefix: true

  belongs_to :user

  after_initialize :set_defaults, if: :new_record?

  def reset
    update DEFAULT_SETTING
  end

  private

  def set_defaults
    assign_attributes DEFAULT_SETTING
  end
end
