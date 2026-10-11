# frozen_string_literal: true

# == Schema Information
#
# Table name: notification_settings
# Database name: primary
#
#  id                 :bigint           not null, primary key
#  article_bought     :jsonb
#  article_published  :jsonb
#  article_rewarded   :jsonb
#  collection_bought  :jsonb
#  collection_listed  :jsonb
#  comment_created    :jsonb
#  tagging_created    :jsonb
#  transfer_processed :jsonb
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  user_id            :bigint
#
# Indexes
#
#  index_notification_settings_on_user_id  (user_id)
#

class NotificationSetting < ApplicationRecord
  DEFAULT_SETTING = NotificationKind.settings_defaults

  # One jsonb column per muteable kind, one accessor per channel.
  NotificationKind.with_settings.each do |kind|
    store kind.settings_key, accessors: NotificationKind::CHANNELS, prefix: true
  end

  belongs_to :user

  after_initialize :set_defaults, if: :new_record?
  before_validation :cast_string_values_to_boolean

  def self.permittable_settings
    NotificationKind.permittable_settings
  end

  def self.boolean_keys
    NotificationKind.with_settings.flat_map { |kind| NotificationKind::CHANNELS.map { |channel| kind.setting_key(channel) } }
  end

  def reset
    update DEFAULT_SETTING
  end

  # A row written before a kind gained settings has no key in its jsonb column;
  # read it as the declared default rather than as "muted". `false` is a real
  # preference and must not be mistaken for a missing key.
  def read_store_attribute(store_attribute, key)
    stored = super
    stored.nil? ? DEFAULT_SETTING.fetch(:"#{store_attribute}_#{key}", nil) : stored
  end

  private

  def set_defaults
    assign_attributes DEFAULT_SETTING
  end

  def cast_string_values_to_boolean
    self.class.boolean_keys.each do |key|
      public_send :"#{key}=", CASTER.cast(public_send(key))
    end
  end

  CASTER = ActiveModel::Type::Boolean.new

  private_constant :CASTER
end
