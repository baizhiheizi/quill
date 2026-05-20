# frozen_string_literal: true

class Dashboard::NotificationsController < Dashboard::BaseController
  def index
    web_notifications = current_user.notifications.for_web.newest_first.select(&:visible_in_web?)
    @pagy, @notifications = pagy_array web_notifications, items: 50
    @active_page = "notification"
  end

  def show
    @notification = current_user.notifications.find(params[:id])
    @notification.mark_as_read!

    redirect_to @notification.url, allow_other_host: true if @notification.url.present?
  end
end
