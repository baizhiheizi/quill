# frozen_string_literal: true

module Authenticatable
  extend ActiveSupport::Concern

  class_methods do
    def auth_from_mixin(token: nil, code: nil)
      token ||= PrsdiggBot.api.oauth_token(code)
      res = PrsdiggBot.api.read_me access_token: token
      raise res.inspect if res['error'].present?

      auth = UserAuthorization.create_with(
        raw: res['data'],
        access_token: token
      ).find_or_create_by!(
        uid: res['data'].fetch('user_id'),
        provider: :mixin
      )
      raw = (auth.raw.presence || {}).merge(res['data'])
      auth.raw = raw
      auth.update! raw: raw if auth.raw_changed?

      if auth.user.present?
        user = auth.user
        user.update_profile raw
      else
        user = create!(
          avatar_url: raw['avatar_url'],
          name: raw['full_name'],
          mixin_id: raw['identity_number'],
          mixin_uuid: raw['user_id']
        )
        auth.update user: user
      end

      user
    end
  end
end
