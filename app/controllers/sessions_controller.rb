# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :ensure_launched!
  skip_before_action :verify_authenticity_token, only: :create

  def new
    redirect_to format(
      '%<oauth_path>s?client_id=%<client_id>s&scope=%<scope>s&return_to=%<return_to>s',
      oauth_path: Settings.mixin_oauth_path || 'https://mixin-www.zeromesh.net/oauth/authorize',
      client_id: PrsdiggBot.api.client_id,
      scope: UserAuthorization::MIXIN_AUTHORIZATION_SCOPE,
      return_to: params[:return_to]
    )
  end

  def create
    user = User.auth_from_mixin params[:code]
    user_sign_in(user) if user

    redirect_to params[:return_to].presence || root_path
  end

  def delete
    user_sign_out

    redirect_to root_path
  end
end
