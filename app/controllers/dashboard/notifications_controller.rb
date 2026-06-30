# frozen_string_literal: true

class Dashboard::NotificationsController < Dashboard::BaseController
  def index
    # `visible_in_web?` (config/initializers/noticed.rb) reads `event.type` and
    # `event.type.constantize` per row to look up the notifier's
    # `persist_web_notification` class attribute. Without `includes(:event)`,
    # those reads issue one `SELECT "noticed_events".*` per row — a 750-row
    # user inbox triggers 750 + 1 SELECTs on the dashboard. Eager-loading the
    # events in a single follow-up SELECT collapses the per-row fan-out.
    web_notifications = current_user.notifications.for_web.newest_first
      .includes(:event).select(&:visible_in_web?)
    @pagy, @notifications = pagy(:offset, web_notifications, limit: 50)
    @active_page = "notification"
  end

  def show
    @notification = current_user.notifications.find(params[:id])
    @notification.mark_as_read!

    redirect_to @notification.url, allow_other_host: true if @notification.url.present?
  end
end
