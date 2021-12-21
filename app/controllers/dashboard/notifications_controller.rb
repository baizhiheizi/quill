# frozen_string_literal: true

class Dashboard::NotificationsController < Dashboard::BaseController
  def index
    @pagy, @notifications = pagy current_user.notifications.order(created_at: :desc)
  end
end
