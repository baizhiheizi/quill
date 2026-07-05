# frozen_string_literal: true

require "test_helper"

class Oauth::SignInTest < ActiveSupport::TestCase
  MIXIN_USER_ID = "e5555555-5555-5555-8555-555555555555"
  IDENTITY_NUMBER = "70001"

  setup do
    UserAuthorization.where(provider: :mixin).destroy_all
    User.where(uid: [ IDENTITY_NUMBER ]).destroy_all
  end

  test "creates a fresh UserAuthorization and User when both are new" do
    identity = mixin_identity

    user = Oauth::SignIn.call(identity:)

    assert_kind_of User, user
    assert_equal "Mixin Reader", user.name
    assert_equal "Hi from Mixin", user.biography
    assert_equal IDENTITY_NUMBER, user.mixin_id
    assert_equal MIXIN_USER_ID, user.mixin_uuid
    assert_equal IDENTITY_NUMBER, user.uid

    auth = user.authorization
    assert_equal "mixin", auth.provider
    assert_equal MIXIN_USER_ID, auth.uid
    assert_equal "fake-token", auth.access_token
    assert_equal IDENTITY_NUMBER, auth.raw["identity_number"]
    assert_equal "Mixin Reader", auth.raw["full_name"]
  end

  test "reuses the existing User when the authorization already has one" do
    existing = create_mixin_user!(
      mixin_uuid: MIXIN_USER_ID,
      name: "Old Name",
      biography: "Old Bio"
    )
    UserAuthorization.create!(
      provider: :mixin,
      uid: MIXIN_USER_ID,
      access_token: "stale-token",
      raw: { "user_id" => MIXIN_USER_ID, "identity_number" => IDENTITY_NUMBER },
      user: existing
    )

    user = Oauth::SignIn.call(identity: mixin_identity(access_token: "fresh-token"))

    assert_equal existing.id, user.id
    auth = user.reload.authorization
    assert_equal "fresh-token", auth.access_token
    assert_equal IDENTITY_NUMBER, auth.raw["identity_number"]
  end

  test "updates existing authorization token and raw without duplicate rows" do
    existing = create_mixin_user!(mixin_uuid: MIXIN_USER_ID, name: "Old Name")
    UserAuthorization.create!(
      provider: :mixin,
      uid: MIXIN_USER_ID,
      access_token: "stale-token",
      raw: { "user_id" => MIXIN_USER_ID, "identity_number" => IDENTITY_NUMBER },
      user: existing
    )

    Oauth::SignIn.call(identity: mixin_identity(access_token: "fresh-token", full_name: "Updated Name"))

    assert_equal 1, UserAuthorization.mixin.where(uid: MIXIN_USER_ID).count
    assert_equal 1, User.where(uid: IDENTITY_NUMBER).count
    assert_equal "fresh-token", UserAuthorization.mixin.find_by(uid: MIXIN_USER_ID).access_token
  end

  test "refreshes name and biography for an existing messenger user" do
    existing = create_mixin_user!(
      mixin_uuid: MIXIN_USER_ID,
      name: "Stale Name",
      biography: "Stale Bio"
    )
    UserAuthorization.create!(
      provider: :mixin,
      uid: MIXIN_USER_ID,
      access_token: "stale-token",
      raw: {
        "user_id" => MIXIN_USER_ID,
        "identity_number" => IDENTITY_NUMBER,
        "full_name" => "Stale Name",
        "biography" => "Stale Bio"
      },
      user: existing
    )

    user = Oauth::SignIn.call(
      identity: mixin_identity(
        access_token: "another-token",
        full_name: "Fresh Name",
        biography: "Fresh Bio"
      )
    )

    assert_equal existing.id, user.id
    assert_equal "Fresh Name", user.reload.name
    assert_equal "Fresh Bio", user.reload.biography
  end

  test "creates user when authorization exists without linked user" do
    UserAuthorization.create!(
      provider: :mixin,
      uid: MIXIN_USER_ID,
      raw: { "user_id" => MIXIN_USER_ID, "identity_number" => IDENTITY_NUMBER }
    )

    user = Oauth::SignIn.call(
      identity: mixin_identity(full_name: "Provisioned Later", biography: "Provisioned")
    )

    assert_equal "Provisioned Later", user.name
    assert_equal IDENTITY_NUMBER, user.mixin_id
    assert_equal MIXIN_USER_ID, user.mixin_uuid
    assert_equal user, user.authorization.reload.user
  end

  test "raises sign in error for invalid identity" do
    identity = Oauth::NormalizedIdentity.new(provider: :mixin, uid: "", access_token: "x", raw: {})

    assert_raises(Oauth::SignInError) { Oauth::SignIn.call(identity:) }
  end

  private

  def mixin_identity(access_token: "fake-token", full_name: "Mixin Reader", biography: "Hi from Mixin")
    Oauth::NormalizedIdentity.new(
      provider: :mixin,
      uid: MIXIN_USER_ID,
      access_token: access_token,
      raw: {
        "user_id" => MIXIN_USER_ID,
        "identity_number" => IDENTITY_NUMBER,
        "full_name" => full_name,
        "biography" => biography
      }
    )
  end

  def create_mixin_user!(mixin_uuid:, name:, biography: nil)
    User.create!(
      name: name,
      biography: biography,
      mixin_id: IDENTITY_NUMBER,
      mixin_uuid: mixin_uuid,
      uid: IDENTITY_NUMBER
    )
  end
end
