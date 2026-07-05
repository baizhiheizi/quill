# frozen_string_literal: true

module Authenticatable
  extend ActiveSupport::Concern

  class_methods do
    def auth_from_mixin(code)
      api = QuillBot.interactive_api
      token = api.oauth_token(code)["access_token"]
      res = api.me access_token: token
      raise res.inspect if res["error"].present?

      auth = UserAuthorization.create_with(
        raw: res["data"],
        access_token: token
      ).find_or_create_by!(
        uid: res["data"].fetch("user_id"),
        provider: :mixin
      )
      raw = (auth.raw.presence || {}).merge(res["data"])
      auth.update raw:, access_token: token

      find_or_create_user_by_auth auth
    end

    private

    def find_or_create_user_by_auth(auth)
      if auth.user.present?
        user = auth.user
        if user.messenger?
          user.update(
            name: auth.raw["full_name"],
            biography: auth.biography
          )
        end
      else
        user = create!(
          name: auth.raw["full_name"],
          biography: auth.raw["biography"],
          mixin_id: auth.raw["identity_number"] || "0",
          mixin_uuid: auth.raw["user_id"],
          uid: auth.mixin? ? auth.raw["identity_number"] : auth.uid.gsub("-", "")
        )
        auth.update user:
      end

      user
    end
  end
end
