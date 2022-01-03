# frozen_string_literal: true

class Dashboard::NotificationSettingsController < Dashboard::BaseController
  def update
    current_user.notification_setting.update setting_params
    current_user.notification_setting.reload
  end

  private

  def setting_params
    params
      .require(:notification_setting)
      .permit(
        :article_published_web,
        :article_published_mixin_bot,
        :article_bought_web,
        :article_bought_mixin_bot,
        :article_rewarded_web,
        :article_rewarded_mixin_bot,
        :tagging_created_web,
        :tagging_created_mixin_bot,
        :comment_created_web,
        :comment_created_mixin_bot,
        :transfer_processed_web,
        :transfer_processed_mixin_bot
      )
  end
end
