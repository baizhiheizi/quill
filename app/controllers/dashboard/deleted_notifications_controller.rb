# frozen_string_literal: true

class Dashboard::DeletedNotificationsController < Dashboard::BaseController
  def create
    current_user.notifications.destroy_all

    redirect_to dashboard_notifications_path
  end
end
