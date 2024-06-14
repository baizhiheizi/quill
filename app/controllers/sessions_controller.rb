# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :ensure_launched!
  skip_before_action :verify_authenticity_token, only: %i[mixin fennec mvm]

  def new
    redirect_to auth_mixin_path(return_to: params[:return_to]) if from_mixin_messenger?
  end

  def mixin_auth
    redirect_to format(
      '%<oauth_path>s?client_id=%<client_id>s&scope=%<scope>s&return_to=%<return_to>s',
      oauth_path: 'https://mixin.one/oauth/authorize',
      client_id: QuillBot.api.client_id,
      scope: 'PROFILE:READ+COLLECTIBLES:READ',
      return_to: params[:return_to]
    ), allow_other_host: true
  end

  def twitter_auth
    client = TwitterBot.oauth_client
    auth_uri =
      client
      .authorization_uri(
        scope: %i[
          users.read
          tweet.read
          offline.access
        ]
      )
    Rails.cache.write client.state, { code_verifier: client.code_verifier, uid: current_user.uid }
    redirect_to auth_uri, allow_other_host: true
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
      user.sync_collectibles_async
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
          params[:address],
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

  def twitter
    auth = Rails.cache.read params[:state]
    redirect_to root_path if auth.blank?

    user = User.find_by uid: auth[:uid]
    redirect_to root_path if user.blank?

    if current_user.blank?
      user_session = user.sessions.create(info: { request: request_info, provider: params[:provider] })
      user_sign_in user_session
    end

    client = TwitterBot.oauth_client
    client.code_verifier = auth[:code_verifier]
    client.authorization_code = params[:code]
    access_token = client.access_token!
    res = JSON.parse access_token.get('https://api.twitter.com/2/users/me?user.fields=profile_image_url').body
    raw = res['data'].merge(access_token: access_token.access_token)

    if current_user.twitter_authorization.present?
      current_user.twitter_authorization.update(
        raw:,
        uid: raw['id']
      )
    else
      current_user.user_authorizations.create(
        provider: :twitter,
        raw:,
        uid: raw['id']
      )
    end
    redirect_to dashboard_settings_path
  rescue Rack::OAuth2::Client::Error
    redirect_to root_path
  end

  def nonce
    return if params[:address].blank?

    session_id = SecureRandom.uuid
    Rails.cache.write params[:address], { session: session_id }.to_json, ex: 5.minutes

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
