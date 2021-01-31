# frozen_string_literal: true

# == Schema Information
#
# Table name: actions
#
#  id            :bigint           not null, primary key
#  action_option :string
#  action_type   :string           not null
#  target_type   :string
#  user_type     :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  target_id     :bigint
#  user_id       :bigint
#
# Indexes
#
#  index_actions_on_target_type_and_target_id_and_action_type  (target_type,target_id,action_type)
#  index_actions_on_user_type_and_user_id_and_action_type      (user_type,user_id,action_type)
#  uk_action_target_user                                       (action_type,target_type,target_id,user_type,user_id) UNIQUE
#
class Action < ApplicationRecord
  belongs_to :target, polymorphic: true, optional: true
  belongs_to :user, polymorphic: true, optional: true

  before_destroy :destroy_notifications
  after_commit :notify_target, on: :create

  def destroy_notifications
    notifications.destroy_all
  end

  def notifications
    @notifications = Notification.where(params: { action: self })
  end

  def notify_target
    case action_type.to_sym
    when :authoring_subscribe
      AuthoringSubscribeActionCreatedNotification.with(action: self).deliver(target)
    when :reading_subscribe
      ReadingSubscribeActionCreatedNotification.with(action: self).deliver(target)
    end
  end
end
