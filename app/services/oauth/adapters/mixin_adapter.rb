# frozen_string_literal: true

module Oauth
  module Adapters
    class MixinAdapter
      def self.call(auth)
        raw = (auth.extra["raw_info"] || auth.extra[:raw_info] || {}).deep_stringify_keys
        uid = raw["user_id"]
        raise Oauth::SignInError, "missing user_id" if uid.blank?

        Oauth::NormalizedIdentity.new(
          provider: :mixin,
          uid: uid,
          access_token: auth.credentials.token,
          raw: raw
        )
      end
    end
  end
end
