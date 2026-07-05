# frozen_string_literal: true

module Oauth
  module Adapters
    # Stub adapter for extensibility tests and future provider registration.
    class TestAdapter
      def self.call(auth)
        raw = (auth.extra["raw_info"] || auth.extra[:raw_info] || {}).deep_stringify_keys

        Oauth::NormalizedIdentity.new(
          provider: :fennec,
          uid: raw.fetch("uid"),
          access_token: auth.credentials.token,
          raw: raw
        )
      end
    end
  end
end
