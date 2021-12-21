# frozen_string_literal: true

class Dashboard::ReadNotificationsController < Dashboard::BaseController
  def create
    current_user.notifications.map(&:mark_as_read!)

    @pagy, @notifications = pagy current_user.notifications.order(created_at: :desc)
  end

  def update
    @notification = current_user.notifications.find(params[:id])
    @notification.mark_as_read!
  end
end
