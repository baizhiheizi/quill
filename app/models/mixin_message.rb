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
    case content
    when 'Hi'
      TextNotificationService.new.call(
        'Welcome to PRSDigg! Write or read to earn.',
        recipient_id: user_id
      )
    when '你好'
      TextNotificationService.new.call(
        '欢迎来到顶瓜瓜。',
        recipient_id: user_id
      )
    else
      AdminNotificationService.new.text(
        "用户 #{user&.name} 有新留言，请在后台查看处理。"
      )
    end
  end

  def touch_proccessed_at
    update processed_at: Time.current
  end

  def process_async
    if plain?
      ProcessMixinMessageWorker.perform_async message_id
    else
      touch_proccessed_at
    end
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
    self.content           = Base64.decode64 data['data'].to_s
  end
end
