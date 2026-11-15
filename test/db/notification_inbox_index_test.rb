# frozen_string_literal: true

require "test_helper"

# The inbox (`notifications.for_web.newest_first`) filters on recipient +
# web_visible and orders by created_at. The composite index serving it ends
# in `created_at`, so Postgres walks the index backwards in order and stops
# at the page boundary instead of sorting the recipient's whole match set —
# the unread-badge queries share the same index prefix.
#
# The index is invisible to the models, so nothing fails when it goes away —
# the inbox just gets slower. This test is the guard.
class NotificationInboxIndexTest < ActiveSupport::TestCase
  test "noticed_notifications is indexed on recipient, web_visible and created_at" do
    index = index_for(:noticed_notifications, "index_noticed_notifications_on_recipient_web_visible_created")

    assert_not_nil index, "noticed_notifications lost its inbox composite index"
    assert_equal %w[recipient_type recipient_id web_visible created_at], index.columns,
                 "created_at must come last so the index can serve ORDER BY created_at DESC"
  end

  private

  def index_for(table, name)
    ActiveRecord::Base.connection.indexes(table).find { |index| index.name == name }
  end
end
