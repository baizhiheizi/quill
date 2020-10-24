# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :create

  def new
    redirect_to format(
      'https://mixin-www.zeromesh.net/oauth/authorize?client_id=%<client_id>s&scope=%<scope>s',
      client_id: MixinBot.api.client_id,
      scope: 'PROFILE:READ'
    )
  end

  def create
    user = User.auth_from_mixin params[:code]
    user_sign_in(user) if user

    redirect_to root_path
  end

  def delete
    user_sign_out

    redirect_to root_path
  end
end
