# frozen_string_literal: true

require "test_helper"

class Oauth::AuthHashNormalizerTest < ActiveSupport::TestCase
  MIXIN_USER_ID = "e5555555-5555-5555-8555-555555555555"
  IDENTITY_NUMBER = "70001"

  test "normalizes mixin auth hash using user_id as uid" do
    auth = mixin_auth_hash

    identity = Oauth::AuthHashNormalizer.call(auth)

    assert_equal :mixin, identity.provider
    assert_equal MIXIN_USER_ID, identity.uid
    assert_equal "fake-token", identity.access_token
    assert_equal MIXIN_USER_ID, identity.raw["user_id"]
    assert_equal IDENTITY_NUMBER, identity.raw["identity_number"]
    assert_equal "Mixin Reader", identity.raw["full_name"]
  end

  test "raises unsupported provider error for unknown providers" do
    auth = OmniAuth::AuthHash.new(provider: "unknown", uid: "1")

    error = assert_raises(Oauth::UnsupportedProviderError) do
      Oauth::AuthHashNormalizer.call(auth)
    end

    assert_match(/unknown/, error.message)
  end

  test "raises sign in error when auth hash is missing" do
    assert_raises(Oauth::SignInError) { Oauth::AuthHashNormalizer.call(nil) }
  end

  test "normalizes stub test_provider auth hash for extensibility" do
    auth = OmniAuth::AuthHash.new(
      provider: "test_provider",
      uid: "stub-uid",
      credentials: OmniAuth::AuthHash.new(token: "stub-token"),
      extra: {
        raw_info: {
          "uid" => "stub-uid",
          "full_name" => "Stub User"
        }
      }
    )

    identity = Oauth::AuthHashNormalizer.call(auth)

    assert_equal :fennec, identity.provider
    assert_equal "stub-uid", identity.uid
    assert_equal "stub-token", identity.access_token
    assert_equal "Stub User", identity.raw["full_name"]
  end

  private

  def mixin_auth_hash
    OmniAuth::AuthHash.new(
      provider: "mixin",
      uid: IDENTITY_NUMBER,
      credentials: OmniAuth::AuthHash.new(token: "fake-token"),
      extra: {
        raw_info: {
          "user_id" => MIXIN_USER_ID,
          "identity_number" => IDENTITY_NUMBER,
          "full_name" => "Mixin Reader",
          "biography" => "Hi from Mixin"
        }
      }
    )
  end
end
