# frozen_string_literal: true

module Oauth
  class AuthHashNormalizer
    ADAPTERS = {
      "mixin" => Adapters::MixinAdapter,
      "test_provider" => Adapters::TestAdapter
    }.freeze

    def self.call(omniauth_auth)
      new(omniauth_auth).call
    end

    def initialize(omniauth_auth)
      @omniauth_auth = omniauth_auth
    end

    def call
      raise Oauth::SignInError, "missing auth hash" if @omniauth_auth.blank?

      adapter_class = ADAPTERS.fetch(provider) do
        raise Oauth::UnsupportedProviderError, "Unsupported provider: #{provider}"
      end

      adapter_class.call(@omniauth_auth)
    end

    private

    def provider
      @omniauth_auth.provider.to_s
    end
  end
end
