# frozen_string_literal: true

# NotificationInboxCompositeIndex left `index_noticed_notifications_on_recipient`
# in place. Its (recipient_type, recipient_id) columns are the leftmost prefix
# of the new composite, so it cannot serve any query the composite cannot —
# every notification insert was still maintaining it. Drop the redundant copy.
class DropRedundantRecipientIndexOnNotifications < ActiveRecord::Migration[8.1]
  def up
    remove_index :noticed_notifications, name: "index_noticed_notifications_on_recipient"
  end

  def down
    add_index :noticed_notifications, %i[recipient_type recipient_id],
              name: "index_noticed_notifications_on_recipient"
  end
end
