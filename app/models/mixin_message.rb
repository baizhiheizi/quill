# frozen_string_literal: true

# == Schema Information
#
# Table name: mixin_messages
#
#  id                      :bigint           not null, primary key
#  action                  :string
#  category                :string
#  content(decrepted data) :string
#  processed_at            :datetime
#  raw                     :json
#  state                   :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  conversation_id         :uuid
#  message_id              :uuid
#  user_id                 :uuid
#
# Indexes
#
#  index_mixin_messages_on_message_id  (message_id) UNIQUE
#

class MixinMessage < ApplicationRecord
  belongs_to :user, primary_key: :mixin_uuid, optional: true

  before_validation :setup_attributes

  validates :message_id, presence: true, uniqueness: true
  validates :raw, presence: true

  after_commit :process_async, on: :create

  scope :unprocessed, -> { where(processed_at: nil) }

  def plain?
    /^PLAIN_/.match? category
  end

  def processed?
    processed_at?
  end

  def process!
    process_user_message

    touch_proccessed_at
  end

  def process_user_message
    return if user.blank?
    return unless conversation_id == QuillBot.api.unique_uuid(user_id)

    user.notify_for_login
  end

  def touch_proccessed_at
    update processed_at: Time.current
  end

  def process_async
    return if user.blank?

    MixinMessages::ProcessJob.perform_later message_id
  end

  private

  def setup_attributes
    return unless new_record?

    data = raw['data']

    self.action            = raw['action']
    self.message_id        = data['message_id']
    self.category          = data['category']
    self.conversation_id   = data['conversation_id']
    self.user_id           = data['user_id']
    self.content           = data['data']
  end
end
