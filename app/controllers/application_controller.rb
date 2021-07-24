# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :ensure_launched!

  helper_method :current_user
  helper_method :base_props
  around_action :with_locale

  private

  def ensure_launched!
    redirect_to landing_path unless launched?
  end

  def launched?
    return true if Settings.launch_time.blank?
    return true if current_user&.mixin_id_in_whitelist?

    Time.current > Time.zone.parse(Settings.launch_time)
  end

  def authenticate_user!
    redirect_to login_path unless current_user
  end

  def current_user
    @current_user = User.find_by(id: session[:current_user_id])
  end

  def user_sign_in(user)
    session[:current_user_id] = user.id
  end

  def user_sign_out
    session[:current_user_id] = nil
    @current_user = nil
  end

  def base_props
    {
      current_user: current_user&.as_json(
        only: %i[name avatar_url mixin_id mixin_uuid banned_at locale]
      )&.merge(
        avatar: current_user.avatar,
        wallet_id: current_user.wallet_id,
        unread_notifications_count: current_user.unread_notifications_count,
        accessable: current_user.accessable?,
        mixin_authorization_valid: current_user.mixin_authorization_valid?
      ),
      prsdigg: {
        app_id: PrsdiggBot.api.client_id,
        app_name: Settings.app_name,
        page_title: Settings.page_title,
        attachment_endpoint: Rails.application.credentials.dig(:aliyun, :bucket_endpoint),
        logo_file: Settings.logo_file || 'logo.png',
        twitter_account: Settings.twitter_account,
        messenger: Settings.messenger || 'mixin'
      },
      default_locale: I18n.default_locale,
      available_locales: I18n.available_locales
    }.deep_transform_keys! { |key| key.to_s.camelize(:lower) }
  end

  def with_locale(&action)
    locale = current_user&.locale || I18n.default_locale
    I18n.with_locale(locale, &action)
  end
end
