# frozen_string_literal: true

class MigrateLegacyNotificationsToNoticed < ActiveRecord::Migration[8.1]
  class TempNotification < ActiveRecord::Base
    self.inheritance_column = nil
    self.table_name = "notifications"
  end

  def up
    return unless table_exists?(:notifications)

    TempNotification.find_each do |notification|
      notifier_type = notification.type.to_s.sub("Notification", "Notifier")
      params = Noticed::Coder.load(notification.params) || {}
      next if params.is_a?(Hash) && params.key?("noticed_error")

      Noticed::Event.create!(
        type: notifier_type,
        params: params,
        created_at: notification.created_at,
        updated_at: notification.updated_at,
        notifications_attributes: [ {
          type: "#{notifier_type}::Notification",
          recipient_type: notification.recipient_type,
          recipient_id: notification.recipient_id,
          read_at: notification.read_at,
          seen_at: notification.read_at,
          created_at: notification.created_at,
          updated_at: notification.updated_at
        } ]
      )
    end

    drop_table :notifications
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
