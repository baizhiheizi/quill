# frozen_string_literal: true

# Denormalises inbox visibility onto `noticed_notifications` and gives the two
# collection kinds the notification settings they used to alias.
#
# * `web_visible` is written from the notification-kind declaration when the row
#   is created, so `for_web` and the badge are indexed queries and no reader has
#   to re-derive visibility from the notifier class.
# * The backfill uses the registry's persisted `type` strings only — orphaned
#   types left behind by a renamed notifier stay invisible instead of raising.
class DenormaliseWebVisibilityOntoNotifications < ActiveRecord::Migration[8.1]
  def up
    add_column :noticed_notifications, :web_visible, :boolean, null: false, default: false
    add_index :noticed_notifications, %i[recipient_type recipient_id web_visible],
              name: "index_noticed_notifications_on_recipient_and_web_visible"

    # The collection kinds used to read the article kinds' toggles; seed the new
    # columns with exactly those values so nobody's preferences change. The
    # payload is copied verbatim: `store` round-trips these jsonb columns through
    # its own coder, so rebuilding the hash here would write a shape the model
    # cannot read back.
    add_column :notification_settings, :collection_listed, :jsonb, default: "{}"
    add_column :notification_settings, :collection_bought, :jsonb, default: "{}"
    execute <<~SQL.squish
      UPDATE notification_settings
      SET collection_listed = article_published,
          collection_bought = article_bought
    SQL

    remove_column :notification_settings, :webhook

    backfill_web_visibility
  end

  def down
    add_column :notification_settings, :webhook, :jsonb, default: "{}"
    remove_column :notification_settings, :collection_listed
    remove_column :notification_settings, :collection_bought

    remove_index :noticed_notifications, name: "index_noticed_notifications_on_recipient_and_web_visible"
    remove_column :noticed_notifications, :web_visible
  end

  private

  def backfill_web_visibility
    # Everything not known to be web-visible stays invisible: the two
    # Mixin-only kinds, and any type no longer declared by a notifier.
    Noticed::Notification.update_all web_visible: false
    Noticed::Notification.where(type: NotificationKind.web_visible_notification_types)
                         .update_all web_visible: true
  end
end
