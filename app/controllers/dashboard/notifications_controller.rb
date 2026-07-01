# frozen_string_literal: true

class Dashboard::NotificationsController < Dashboard::BaseController
  def index
    # `visible_in_web?` reads `event.type.constantize` per row; eager-load to
    # avoid an N+1 SELECT on `noticed_events` for large inboxes.
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
