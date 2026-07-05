# frozen_string_literal: true

module Oauth
  class SignIn
    def self.call(identity:, request_info: nil)
      new(identity:, request_info:).call
    end

    def initialize(identity:, request_info: nil)
      @identity = identity
      @request_info = request_info
    end

    def call
      validate_identity!

      auth = upsert_authorization
      find_or_create_user(auth)
    end

    private

    attr_reader :identity, :request_info

    def validate_identity!
      raise Oauth::SignInError, "missing provider" if identity.provider.blank?
      raise Oauth::SignInError, "missing uid" if identity.uid.blank?
      raise Oauth::SignInError, "missing raw profile" if identity.raw.blank?
    end

    def upsert_authorization
      auth = UserAuthorization.create_with(
        raw: identity.raw,
        access_token: identity.access_token
      ).find_or_create_by!(
        uid: identity.uid,
        provider: identity.provider
      )
      raw = (auth.raw.presence || {}).merge(identity.raw)
      auth.update! raw:, access_token: identity.access_token
      auth
    end

    def find_or_create_user(auth)
      if auth.user.present?
        user = auth.user
        refresh_messenger_profile(user, auth) if user.messenger?
        return user
      end

      user = User.create!(user_attributes(auth))
      auth.update!(user: user)
      user
    end

    def refresh_messenger_profile(user, auth)
      user.update(
        name: auth.raw["full_name"],
        biography: auth.biography
      )
    end

    def user_attributes(auth)
      if auth.mixin?
        {
          name: auth.raw["full_name"],
          biography: auth.biography,
          mixin_id: auth.raw["identity_number"] || "0",
          mixin_uuid: auth.raw["user_id"],
          uid: auth.raw["identity_number"]
        }
      else
        {
          name: auth.raw["full_name"],
          biography: auth.biography,
          uid: auth.uid.gsub("-", "")
        }
      end
    end
  end
end
