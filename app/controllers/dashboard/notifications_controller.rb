# frozen_string_literal: true

class Dashboard::NotificationsController < Dashboard::BaseController
  def index
    # Visibility is a column, so the whole inbox is paginated SQL. The event is
    # preloaded because the partial reads `params` (message / url / icon) per row.
    @pagy, @notifications = pagy(
      :offset,
      current_user.notifications.for_web.newest_first.includes(:event),
      limit: 50
    )
    @active_page = "notification"
  end

  def show
    @notification = current_user.notifications.find(params[:id])
    @notification.mark_as_read!

    redirect_to @notification.url, allow_other_host: true if @notification.url.present?
  end
end
