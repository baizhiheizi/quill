# frozen_string_literal: true

module Oauth
  class CallbacksController < ApplicationController
    skip_before_action :ensure_launched!

    def create
      identity = Oauth::AuthHashNormalizer.call(request.env["omniauth.auth"])
      user = Oauth::SignIn.call(identity:, request_info:)
      user_sign_in user.sessions.create!(info: request_info)
      user.notify_for_login
      redirect_to oauth_return_to_path, success: t("connected")
    rescue MixinBot::RateLimitError
      redirect_to oauth_return_to_path, alert: t("mixin_rate_limited")
    rescue Oauth::SignInError, Oauth::UnsupportedProviderError
      redirect_to oauth_return_to_path, alert: t("failed_to_connect")
    end

    def failure
      redirect_to oauth_return_to_path, alert: t("failed_to_connect")
    end

    private

    def request_info
      {
        ip: request.ip,
        user_agent: request.user_agent
      }
    end

    def oauth_return_to_path
      target = omniauth_params["return_to"].presence || params[:return_to]
      url_from(target) || root_path
    end

    def omniauth_params
      request.env["omniauth.params"] || {}
    end
  end
end
