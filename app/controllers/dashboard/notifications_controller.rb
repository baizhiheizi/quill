# frozen_string_literal: true

class Dashboard::NotificationsController < Dashboard::BaseController
  def index
    @pagy, @notifications = pagy current_user.notifications.order(created_at: :desc)
    @active_page = 'notification'
  end

  def show
    @notification = current_user.notifications.find(params[:id])
    @notification.mark_as_read!

    redirect_to @notification.url, allow_other_host: true if @notification.url.present?
  end
end
