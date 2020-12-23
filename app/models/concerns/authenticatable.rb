# frozen_string_literal: true

module Authenticatable
  extend ActiveSupport::Concern

  class_methods do
    def auth_from_mixin(code)
      access_token = PrsdiggBot.api.oauth_token(code)
      res = PrsdiggBot.api.read_me access_token: access_token
      raise res.inspect if res['error'].present?

      auth = UserAuthorization.create_with(
        raw: res['data'],
        access_token: access_token
      ).find_or_create_by!(
        uid: res['data'].fetch('user_id'),
        provider: :mixin
      )
      raw = (auth.raw.presence || {}).merge(res['data'])
      auth.raw = raw
      if auth.raw_changed?
        auth.update! raw: raw
        auth.user.update_profile raw
      end

      find_or_create_by!(mixin_authorization: auth)
    end
  end
end
