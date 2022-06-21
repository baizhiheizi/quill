# frozen_string_literal: true

# == Schema Information
#
# Table name: notifications
#
#  id             :bigint           not null, primary key
#  params         :jsonb
#  read_at        :datetime
#  recipient_type :string           not null
#  type           :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  recipient_id   :bigint           not null
#
# Indexes
#
#  index_notifications_on_read_at    (read_at)
#  index_notifications_on_recipient  (recipient_type,recipient_id)
#

class Notification < ApplicationRecord
  include Noticed::Model

  belongs_to :recipient, polymorphic: true

  delegate :message, to: :to_notification
  delegate :url, to: :to_notification

  after_create_commit { broadcast_as_flash }

  def broadcast_as_flash
    broadcast_prepend_later_to "user_#{recipient.mixin_uuid}", target: 'notifications', partial: 'notifications/notification', locals: { message: to_notification.message, type: :info }
  end
end
