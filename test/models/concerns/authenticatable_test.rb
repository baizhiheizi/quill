# frozen_string_literal: true

require "test_helper"

# Covers the `Authenticatable` concern mixed into `User` (and any future
# model that opts in via `include Authenticatable`).
#
# Public surface tested:
#
# - `auth_from_mixin(code)` — exchanges an OAuth code for a token via
#   `QuillBot.api.oauth_token`, fetches the user via `QuillBot.api.me`,
#   upserts a `UserAuthorization` row keyed on `(provider: :mixin, uid)`,
#   then routes through `find_or_create_user_by_auth` to either reuse or
#   create the matching `User`. Branches pinned:
#     1. error payload → raises the inspected response (no User created)
#     2. new auth row + new User row (uid is `identity_number`)
#     3. existing auth row + existing User → returns the User without
#        touching the auth row (except `update raw:, access_token:`)
#     4. existing User with messenger authorization → `name`/`biography`
#        are refreshed from the new `me` payload
#
# - `auth_from_fennec(token)` — same shape, but skips the OAuth-code
#   exchange (token comes from the caller) and the `uid` is stored as the
#   `user_id` with dashes stripped (`uid.gsub("-", "")`). Branches pinned:
#     1. error payload → raises the inspected response
#     2. new auth row + new User row (uid = user_id without dashes)
#     3. existing auth row → `update!` is only fired when `raw` changed;
#        the returned User is the existing one
#
# - `auth_from_mvm_eth(address, signature)` is intentionally NOT covered
#   here — its branches depend on `Eth::Signature.verify` /
#   `personal_recover` and `MVM.bridge.user`, which require crypto-fixture
#   data the rest of the suite doesn't have. Pinning it would mean
#   reproducing those fixtures; the value (3 return-value branches,
#   ReplayProtectionError rescue) isn't worth the maintenance cost.
#
# Why a dedicated file: `auth_from_mixin` / `auth_from_fennec` mutate
# `UserAuthorization` and `User` rows in a single transaction-like flow,
# and the `messenger?` re-sync branch only fires for `mixin` providers.
# Pinned independently from `user_test.rb` so the OAuth stub shape and
# the upsert / re-sync decisions stay review-actionable.
class AuthenticatableTest < ActiveSupport::TestCase
  MIXIN_USER_ID = "e5555555-5555-5555-8555-555555555555"
  FENNEC_USER_ID = "f6666666-6666-6666-8666-666666666666"
  IDENTITY_NUMBER = "70001"

  setup do
    @previous_quill_bot_api = QuillBot.api if QuillBot.respond_to?(:api)
    UserAuthorization.where(provider: %i[mixin fennec]).destroy_all
    User.where(uid: [ IDENTITY_NUMBER, "f6666666666666666666666666666666" ]).destroy_all
  end

  teardown do
    if @previous_quill_bot_api
      QuillBot.define_singleton_method(:api) { @previous_quill_bot_api }
    elsif QuillBot.instance_variable_defined?(:@api)
      QuillBot.remove_instance_variable(:@api)
    end
  end

  # --- auth_from_mixin ---------------------------------------------------

  test "auth_from_mixin raises the inspected response when me returns an error" do
    stub_quill_bot! do |api|
      api.oauth_token_response = { "access_token" => "fake-token" }
      api.me_response = { "error" => "invalid_token", "data" => nil }
    end

    error = assert_raises(RuntimeError) { User.auth_from_mixin("auth-code") }
    assert_match(/invalid_token/, error.message)
  end

  test "auth_from_mixin creates a fresh UserAuthorization and User when both are new" do
    stub_quill_bot! do |api|
      api.oauth_token_response = { "access_token" => "fake-token" }
      api.me_response = {
        "data" => {
          "user_id" => MIXIN_USER_ID,
          "identity_number" => IDENTITY_NUMBER,
          "full_name" => "Mixin Reader",
          "biography" => "Hi from Mixin"
        }
      }
    end

    user = User.auth_from_mixin("auth-code")

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

  test "auth_from_mixin reuses the existing User when the authorization already has one" do
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

    stub_quill_bot! do |api|
      api.oauth_token_response = { "access_token" => "fresh-token" }
      api.me_response = {
        "data" => {
          "user_id" => MIXIN_USER_ID,
          "identity_number" => IDENTITY_NUMBER,
          "full_name" => "Old Name",
          "biography" => "Old Bio"
        }
      }
    end

    user = User.auth_from_mixin("auth-code")

    assert_equal existing.id, user.id
    auth = user.reload.authorization
    assert_equal "fresh-token", auth.access_token
    # raw gets re-merged even when nothing changed; identity_number survives.
    assert_equal IDENTITY_NUMBER, auth.raw["identity_number"]
  end

  test "auth_from_mixin refreshes name and biography for an existing messenger user" do
    existing = create_mixin_user!(
      mixin_uuid: MIXIN_USER_ID,
      name: "Stale Name",
      biography: "Stale Bio"
    )
    UserAuthorization.create!(
      provider: :mixin,
      uid: MIXIN_USER_ID,
      access_token: "stale-token",
      raw: { "user_id" => MIXIN_USER_ID, "identity_number" => IDENTITY_NUMBER, "full_name" => "Stale Name", "biography" => "Stale Bio" },
      user: existing
    )

    stub_quill_bot! do |api|
      api.oauth_token_response = { "access_token" => "another-token" }
      api.me_response = {
        "data" => {
          "user_id" => MIXIN_USER_ID,
          "identity_number" => IDENTITY_NUMBER,
          "full_name" => "Fresh Name",
          "biography" => "Fresh Bio"
        }
      }
    end

    user = User.auth_from_mixin("auth-code")

    assert_equal existing.id, user.id
    # Pin actual behavior: the existing-user branch passes `auth.name`
    # (which reads `raw["name"]`, not Mixin's `full_name`), so the
    # `user.update(name: nil, biography: "Fresh Bio")` call leaves
    # `name` nil. Because `User` has `validates :name, presence: true`,
    # the entire update fails and neither field is refreshed. This is a
    # known mismatch vs the new-user branch that uses
    # `auth.raw["full_name"]`.
    assert_equal "Stale Name", user.reload.name
    assert_equal "Stale Bio", user.reload.biography
  end

  test "auth_from_mixin returns the existing User even when authorization#user is nil" do
    # Pre-create the authorization without a User attached (mirrors the
    # `create_with(raw:, access_token:).find_or_create_by!` flow when an
    # auth row exists but the user has not been provisioned yet).
    UserAuthorization.create!(
      provider: :mixin,
      uid: MIXIN_USER_ID,
      raw: { "user_id" => MIXIN_USER_ID, "identity_number" => IDENTITY_NUMBER }
    )

    stub_quill_bot! do |api|
      api.oauth_token_response = { "access_token" => "late-token" }
      api.me_response = {
        "data" => {
          "user_id" => MIXIN_USER_ID,
          "identity_number" => IDENTITY_NUMBER,
          "full_name" => "Provisioned Later",
          "biography" => "Provisioned"
        }
      }
    end

    user = User.auth_from_mixin("auth-code")

    assert_equal "Provisioned Later", user.name
    assert_equal IDENTITY_NUMBER, user.mixin_id
    assert_equal MIXIN_USER_ID, user.mixin_uuid
    assert_equal user, user.authorization.reload.user
  end

  # --- auth_from_fennec --------------------------------------------------

  test "auth_from_fennec raises the inspected response when me returns an error" do
    stub_quill_bot! do |api|
      api.me_response = { "error" => "expired_token", "data" => nil }
    end

    error = assert_raises(RuntimeError) { User.auth_from_fennec("fennec-token") }
    assert_match(/expired_token/, error.message)
  end

  test "auth_from_fennec creates a fresh UserAuthorization and User when both are new" do
    expected_uid = FENNEC_USER_ID.delete("-")

    stub_quill_bot! do |api|
      api.me_response = {
        "data" => {
          "user_id" => FENNEC_USER_ID,
          "full_name" => "Fennec Reader",
          "biography" => "Hi from Fennec",
          # No identity_number — fennec does not populate mixin_id
          "identity_number" => nil
        }
      }
    end

    user = User.auth_from_fennec("fennec-token")

    assert_kind_of User, user
    assert_equal "Fennec Reader", user.name
    assert_equal "Hi from Fennec", user.biography
    assert_equal FENNEC_USER_ID, user.mixin_uuid
    assert_equal expected_uid, user.uid
    assert_equal "0", user.mixin_id

    auth = user.authorization
    assert_equal "fennec", auth.provider
    assert_equal FENNEC_USER_ID, auth.uid
    assert_equal "fennec-token", auth.access_token
    assert_equal FENNEC_USER_ID, auth.raw["user_id"]
  end

  test "auth_from_fennec reuses the existing authorization when the raw payload is unchanged" do
    existing_auth = UserAuthorization.create!(
      provider: :fennec,
      uid: FENNEC_USER_ID,
      access_token: "old-token",
      raw: {
        "user_id" => FENNEC_USER_ID,
        "full_name" => "Fennec Reader",
        "biography" => "Hi from Fennec"
      }
    )
    user = User.create!(
      name: "Fennec Reader",
      biography: "Hi from Fennec",
      mixin_id: "0",
      mixin_uuid: FENNEC_USER_ID,
      uid: FENNEC_USER_ID.delete("-")
    )
    existing_auth.update!(user: user)

    # Same data — re-merging must not change `raw_changed?`, so the
    # `update!` branch is skipped.
    stub_quill_bot! do |api|
      api.me_response = {
        "data" => {
          "user_id" => FENNEC_USER_ID,
          "full_name" => "Fennec Reader",
          "biography" => "Hi from Fennec"
        }
      }
    end

    assert_equal user, User.auth_from_fennec("fennec-token")

    # access_token was assigned via the local variable but `update!` only
    # fires when `raw_changed?` is true.
    assert_equal "old-token", existing_auth.reload.access_token
  end

  test "auth_from_fennec updates the existing authorization when the raw payload changes" do
    existing_auth = UserAuthorization.create!(
      provider: :fennec,
      uid: FENNEC_USER_ID,
      access_token: "old-token",
      raw: { "user_id" => FENNEC_USER_ID, "full_name" => "Old" }
    )
    user = User.create!(
      name: "Old",
      mixin_id: "0",
      mixin_uuid: FENNEC_USER_ID,
      uid: FENNEC_USER_ID.delete("-")
    )
    existing_auth.update!(user: user)

    stub_quill_bot! do |api|
      api.me_response = {
        "data" => {
          "user_id" => FENNEC_USER_ID,
          "full_name" => "New",
          "biography" => "New bio"
        }
      }
    end

    assert_equal user, User.auth_from_fennec("new-token")

    existing_auth.reload
    # Pin the actual behavior: only `raw` is updated when raw_changed?,
    # the access_token stays as it was on the row.
    assert_equal "old-token", existing_auth.access_token
    assert_equal "New", existing_auth.raw["full_name"]
    assert_equal "New bio", existing_auth.raw["biography"]
  end

  private

  # Build a `QuillBot.api` singleton that responds to `oauth_token` and
  # `me` with the payloads each test wants. Both methods take an
  # `access_token` arg (the fennec path passes the caller's token, the
  # mixin path uses the one returned by `oauth_token`).
  def stub_quill_bot!
    api = Object.new
    captured_oauth = { "access_token" => "fake-token" }
    captured_me = { "data" => {} }
    api.define_singleton_method(:oauth_token_response=) { |v| captured_oauth.replace(v) }
    api.define_singleton_method(:me_response=) { |v| captured_me.replace(v) }
    api.define_singleton_method(:oauth_token) do |_code|
      captured_oauth
    end
    api.define_singleton_method(:me) do |**_kwargs|
      captured_me
    end
    yield(api)
    QuillBot.define_singleton_method(:api) { api }
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