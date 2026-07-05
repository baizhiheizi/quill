# frozen_string_literal: true

module Oauth
  NormalizedIdentity = Data.define(:provider, :uid, :access_token, :raw)
end
