# frozen_string_literal: true

require "test_helper"

class Oauth::Adapters::MixinAdapterTest < ActiveSupport::TestCase
  MIXIN_USER_ID = "e5555555-5555-5555-8555-555555555555"
  IDENTITY_NUMBER = "70001"

  test "normalizes an OmniAuth auth hash with string-key raw_info" do
    identity = call_adapter(
      extra: {
        raw_info: {
          "user_id" => MIXIN_USER_ID,
          "identity_number" => IDENTITY_NUMBER,
          "full_name" => "Mixin Reader"
        }
      }
    )

    assert_equal :mixin, identity.provider
    assert_equal MIXIN_USER_ID, identity.uid
    assert_equal "fake-token", identity.access_token
    assert_equal MIXIN_USER_ID, identity.raw["user_id"]
    assert_equal IDENTITY_NUMBER, identity.raw["identity_number"]
    assert_equal "Mixin Reader", identity.raw["full_name"]
  end

  test "falls back to symbol-key raw_info when string-key is absent" do
    identity = call_adapter(
      extra: {
        raw_info: {
          user_id: MIXIN_USER_ID,
          identity_number: IDENTITY_NUMBER,
          full_name: "Symbol Reader"
        }
      }
    )

    assert_equal :mixin, identity.provider
    assert_equal MIXIN_USER_ID, identity.uid
    assert_equal "Symbol Reader", identity.raw["full_name"]
  end

  test "deep-stringifies symbol-keyed raw_info" do
    identity = call_adapter(
      extra: {
        raw_info: {
          user_id: MIXIN_USER_ID,
          nested: { value: 42 }
        }
      }
    )

    assert_equal 42, identity.raw.dig("nested", "value")
    assert_equal [ "user_id", "nested" ], identity.raw.keys
    assert_equal [ "value" ], identity.raw["nested"].keys
  end

  test "raises sign in error when raw_info is missing user_id" do
    auth = OmniAuth::AuthHash.new(
      provider: "mixin",
      uid: IDENTITY_NUMBER,
      credentials: OmniAuth::AuthHash.new(token: "fake-token"),
      extra: {}
    )

    error = assert_raises(Oauth::SignInError) { Oauth::Adapters::MixinAdapter.call(auth) }

    assert_match(/missing user_id/, error.message)
  end

  test "raises sign in error when user_id is blank" do
    auth = OmniAuth::AuthHash.new(
      provider: "mixin",
      uid: IDENTITY_NUMBER,
      credentials: OmniAuth::AuthHash.new(token: "fake-token"),
      extra: {
        raw_info: { "user_id" => "" }
      }
    )

    assert_raises(Oauth::SignInError) { Oauth::Adapters::MixinAdapter.call(auth) }
  end

  private

  def call_adapter(extra:)
    auth = OmniAuth::AuthHash.new(
      provider: "mixin",
      uid: IDENTITY_NUMBER,
      credentials: OmniAuth::AuthHash.new(token: "fake-token"),
      extra: extra
    )

    Oauth::Adapters::MixinAdapter.call(auth)
  end
end
