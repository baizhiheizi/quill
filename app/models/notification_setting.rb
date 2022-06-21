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
  before_validation :cast_string_value_to_boolean

  def reset
    update DEFAULT_SETTING
  end

  private

  def set_defaults
    assign_attributes DEFAULT_SETTING
  end

  def cast_string_value_to_boolean
    self.article_published_web = ActiveModel::Type::Boolean.new.cast article_published_web
    self.article_published_mixin_bot = ActiveModel::Type::Boolean.new.cast article_published_mixin_bot
    self.article_published_webhook = ActiveModel::Type::Boolean.new.cast article_published_webhook

    self.article_bought_web = ActiveModel::Type::Boolean.new.cast article_bought_web
    self.article_bought_mixin_bot = ActiveModel::Type::Boolean.new.cast article_bought_mixin_bot
    self.article_bought_webhook = ActiveModel::Type::Boolean.new.cast article_bought_webhook

    self.article_rewarded_web = ActiveModel::Type::Boolean.new.cast article_rewarded_web
    self.article_rewarded_mixin_bot = ActiveModel::Type::Boolean.new.cast article_rewarded_mixin_bot
    self.article_rewarded_webhook = ActiveModel::Type::Boolean.new.cast article_rewarded_webhook

    self.comment_created_web = ActiveModel::Type::Boolean.new.cast comment_created_web
    self.comment_created_mixin_bot = ActiveModel::Type::Boolean.new.cast comment_created_mixin_bot
    self.comment_created_webhook = ActiveModel::Type::Boolean.new.cast comment_created_webhook

    self.tagging_created_web = ActiveModel::Type::Boolean.new.cast tagging_created_web
    self.tagging_created_mixin_bot = ActiveModel::Type::Boolean.new.cast tagging_created_mixin_bot
    self.tagging_created_webhook = ActiveModel::Type::Boolean.new.cast tagging_created_webhook

    self.transfer_processed_web = ActiveModel::Type::Boolean.new.cast transfer_processed_web
    self.transfer_processed_mixin_bot = ActiveModel::Type::Boolean.new.cast transfer_processed_mixin_bot
    self.transfer_processed_webhook = ActiveModel::Type::Boolean.new.cast transfer_processed_webhook
  end
end
