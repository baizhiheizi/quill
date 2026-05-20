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

# rubocop:disable Rails/ApplicationRecord
class Action < ActiveRecord::Base
  # rubocop:enable Rails/ApplicationRecord
  belongs_to :target, polymorphic: true, optional: true
  belongs_to :user, polymorphic: true, optional: true

  has_many :noticed_events, as: :record, dependent: :destroy, class_name: "Noticed::Event"

  after_create :notify_target
  before_destroy :destroy_notifications

  def notifications
    noticed_events
  end

  def destroy_notifications
    noticed_events.destroy_all
  rescue StandardError => e
    Rails.logger.error "Failed to destroy notifications for action #{id}: #{e}"
  end

  def notify_target
    return unless target.is_a?(User)

    case action_type.to_sym
    when :subscribe
      SubscribeUserActionCreatedNotifier.with(record: self, action: self).deliver(target)
    end
  end
end
