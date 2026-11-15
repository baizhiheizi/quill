# frozen_string_literal: true

# The inbox (`notifications.for_web.newest_first`) filters on
# recipient + web_visible and orders by created_at. The previous index stopped
# at web_visible, so every page view sorted the recipient's whole match set
# before applying LIMIT 50. Extending the index with created_at lets Postgres
# walk it in order and stop at the page boundary.
class NotificationInboxCompositeIndex < ActiveRecord::Migration[8.1]
  def up
    remove_index :noticed_notifications, name: "index_noticed_notifications_on_recipient_and_web_visible"
    add_index :noticed_notifications, %i[recipient_type recipient_id web_visible created_at],
              name: "index_noticed_notifications_on_recipient_web_visible_created"
    execute "ANALYZE noticed_notifications"
  end

  def down
    remove_index :noticed_notifications, name: "index_noticed_notifications_on_recipient_web_visible_created"
    add_index :noticed_notifications, %i[recipient_type recipient_id web_visible],
              name: "index_noticed_notifications_on_recipient_and_web_visible"
  end
end
