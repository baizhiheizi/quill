# frozen_string_literal: true

module Authenticatable
  extend ActiveSupport::Concern

  class_methods do
    def auth_from_mixin(code)
      access_token = MixinBot.api.oauth_token(code)
      res = MixinBot.api.read_me access_token: access_token
      raise res.inspect if res['error'].present?

      auth = UserAuthorization.create_with(
        raw: res['data'],
        access_token: access_token
      ).find_or_create_by!(
        uid: res['data'].fetch('user_id'),
        provider: :mixin
      )
      auth.raw = (auth.raw.presence || {}).merge(res['data'])
      auth.update! raw: raw if auth.raw_changed?

      find_or_create_by!(mixin_authorization: auth)
    end
  end
end
