# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :ensure_launched!
  skip_before_action :verify_authenticity_token, only: %i[mixin fennec mvm]

  def new
    redirect_to format(
      '%<oauth_path>s?client_id=%<client_id>s&scope=%<scope>s&return_to=%<return_to>s',
      oauth_path: Settings.mixin_oauth_path || 'https://mixin-www.zeromesh.net/oauth/authorize',
      client_id: PrsdiggBot.api.client_id,
      scope: UserAuthorization::MIXIN_AUTHORIZATION_SCOPE,
      return_to: params[:return_to]
    ), allow_other_host: true
  end

  def mixin
    user = User.auth_from_mixin params[:code]
    user_sign_in(user) if user

    redirect_to params[:return_to].presence || root_path
  end

  def fennec
    user = User.auth_from_fennec params[:token]
    user_sign_in(user) if user

    redirect_to params[:return_to].presence || root_path
  end

  def mvm
    user = User.auth_from_mvm_eth params[:public_key], params[:signature]
    user_sign_in(user) if user

    redirect_to params[:return_to].presence || root_path
  end

  def nounce
    return if params[:public_key].blank?

    nounce = SecureRandom.random_number 1_000_000
    Global.redis.set params[:public_key], { nounce: nounce }.to_json, ex: 5.minutes

    render json: { nounce: nounce }
  end

  def delete
    user_sign_out

    redirect_to root_path
  end
end
