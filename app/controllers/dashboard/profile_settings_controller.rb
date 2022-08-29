# frozen_string_literal: true

class Dashboard::ProfileSettingsController < Dashboard::BaseController
  skip_before_action :authenticate_user!, only: :verify_email

  layout 'application', only: :verify_email

  def edit
  end

  def update
    current_user.update setting_params
    current_user.send_verify_email if current_user.email_may_verify?

    current_user.reload
  end

  def verify_email
    email = Rails.cache.fetch params[:code]
    @user = User.find_by email: email if email.present?
    return if @user.blank?

    @user.email_verify!
    Rails.cache.delete params[:code]
  end

  private

  def setting_params
    params
      .require(:user)
      .permit(
        :email
      )
  end
end
