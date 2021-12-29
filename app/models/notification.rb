# frozen_string_literal: true

# == Schema Information
#
# Table name: notifications
#
#  id             :integer          not null, primary key
#  recipient_type :string           not null
#  recipient_id   :integer          not null
#  type           :string           not null
#  params         :jsonb
#  read_at        :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
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
    broadcast_append_later_to "user_#{recipient.mixin_uuid}", target: 'notifications', partial: 'shared/notification', locals: { message: to_notification.message, type: 'notice' }
  end
end
