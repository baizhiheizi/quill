# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :ensure_launched!
  skip_before_action :verify_authenticity_token, only: %i[mixin fennec mvm]

  def new
    redirect_to mixin_login_path if from_mixin_messenger?
  end

  def mixin_login
    redirect_to format(
      '%<oauth_path>s?client_id=%<client_id>s&scope=%<scope>s&return_to=%<return_to>s',
      oauth_path: Settings.mixin_oauth_path || 'https://mixin-www.zeromesh.net/oauth/authorize',
      client_id: QuillBot.api.client_id,
      scope: UserAuthorization::MIXIN_AUTHORIZATION_SCOPE,
      return_to: params[:return_to]
    ), allow_other_host: true
  end

  def mixin
    user =
      begin
        User.auth_from_mixin params[:code]
      rescue MixinBot::Error
        nil
      end

    if user.present?
      user_sign_in user.sessions.create!(info: { request: request_info })
      user.notify_for_login
      redirect_to (params[:return_to].presence || root_path), success: t('connected')
    else
      redirect_to (params[:return_to].presence || root_path), alert: t('failed_to_connect')
    end
  end

  def fennec
    user =
      begin
        User.auth_from_fennec params[:token]
      rescue MixinBot::Error
        nil
      end

    if user.present?
      user_sign_in user.sessions.create! info: { request: request_info }
      redirect_to (params[:return_to].presence || root_path), success: t('connected')
    else
      redirect_to (params[:return_to].presence || root_path), alert: t('failed_to_connect')
    end
  end

  def mvm
    user, session_id =
      begin
        User.auth_from_mvm_eth(
          params[:public_key],
          params[:signature]
        )
      rescue MVM::Error => e
        raise e if Rails.env.development?

        nil
      end

    if user.present?
      user_session = user.sessions.create(uuid: session_id, info: { request: request_info, provider: params[:provider] })
      user_sign_in user_session
      redirect_to (params[:return_to].presence || root_path), success: t('connected')
    else
      redirect_to (params[:return_to].presence || root_path), alert: t('failed_to_connect')
    end
  end

  def nounce
    return if params[:public_key].blank?

    session_id = SecureRandom.uuid
    Rails.cache.write params[:public_key], { session: session_id }.to_json, ex: 5.minutes

    render json: { session: session_id }
  end

  def delete
    user_sign_out

    redirect_to root_path
  end

  private

  def request_info
    {
      ip: request.ip,
      user_agent: request.user_agent
    }
  end
end
