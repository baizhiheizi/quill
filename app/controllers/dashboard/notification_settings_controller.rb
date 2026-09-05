# frozen_string_literal: true

class Dashboard::NotificationSettingsController < Dashboard::BaseController
  def update
    current_user.notification_setting.update setting_params
    current_user.notification_setting.reload
  end

  private

  def setting_params
    params.require(:notification_setting).permit(NotificationSetting.permittable_settings)
  end
end
