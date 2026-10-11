# frozen_string_literal: true

class Dashboard::ReadNotificationsController < Dashboard::BaseController
  def new
  end

  def create
    current_user.notifications.unread.each do |notification|
      notification.mark_as_read!
    rescue ActiveJob::SerializationError
      notification.destroy!
    end

    redirect_to dashboard_notifications_path
  end

  def update
    @notification = current_user.notifications.find_by(id: params[:id])
    return head :not_found if @notification.blank?

    @notification.mark_as_read!
  end
end
