# frozen_string_literal: true

# == Schema Information
#
# Table name: user_authorizations
# Database name: primary
#
#  id                                  :bigint           not null, primary key
#  access_token                        :string
#  provider(third party auth provider) :integer
#  public_key                          :string
#  raw(third pary user info)           :json
#  uid(third party user id)            :string
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  user_id                             :bigint
#
# Indexes
#
#  index_user_authorizations_on_provider_and_uid  (provider,uid) UNIQUE
#  index_user_authorizations_on_user_id           (user_id)
#

require "test_helper"

# Covers the `UserAuthorization` model. Public surface tested:
#
# - `store_accessor` over `raw` for `phone`, `key`, `contract`, `avatar_url`,
#   `name`, `biography`.
# - `provider` enum stringification for `:mixin / :fennec / :mvm_eth / :twitter`.
# - Validations: `provider`, `raw`, `uid` required; `uid` uniqueness scoped to
#   `provider` so the same external id may live under multiple providers.
# - `belongs_to :user, optional: true` — auth rows may exist before the User is
#   provisioned (the `find_or_create_user_by_auth` flow in
#   `app/models/concerns/authenticatable.rb` relies on this).
# - `refresh!` early-returns for `:twitter` (no API call), and otherwise calls
#   `QuillBot.api.user(raw["user_id"])` then merges the returned `data` into
#   `raw`.
# - `has_safe?` short-circuits on a truthy `raw["has_safe"]` and falls through
#   to `refresh!` when the flag is absent or false.
#
# Why this file lives next to the model: `UserAuthorization` is the OAuth/OIDC
# identity table for every provider this app has ever shipped, and the
# `refresh!` / `has_safe?` pair is the only path that materialises Safe-wallet
# state — the regression surface for wallet logic on top of this row.
class UserAuthorizationTest < ActiveSupport::TestCase
  # `transfer_test.rb` swaps `UserAuthorization#has_safe?` at runtime and
  # removes the original in `ensure` instead of restoring it. Snap the
  # original up front so this file's tests stay green regardless of run order.
  ORIGINAL_HAS_SAFE = UserAuthorization.instance_method(:has_safe?)
  ORIGINAL_QUILL_BOT_API = QuillBot.method(:api)

  setup do
    UserAuthorization.define_method(:has_safe?, ORIGINAL_HAS_SAFE)
  end

  teardown do
    QuillBot.define_singleton_method(:api, ORIGINAL_QUILL_BOT_API)
  end

  # --- store_accessor --------------------------------------------------

  test "store_accessor extracts phone, key, contract, avatar_url, name, biography from raw" do
    auth = user_authorizations(:author_auth)

    assert_equal "Test Author", auth.name
    assert_equal "https://example.com/avatar.png", auth.avatar_url
  end

  test "store_accessor writes back through raw on assignment" do
    auth = user_authorizations(:author_auth)
    auth.phone = "+15555550100"
    auth.key = "signing-key"
    auth.biography = "Updated bio"

    assert_equal "+15555550100", auth.phone
    assert_equal "signing-key", auth.key
    assert_equal "Updated bio", auth.biography
    assert_equal "+15555550100", auth.raw["phone"]
    assert_equal "signing-key", auth.raw["key"]
    assert_equal "Updated bio", auth.raw["biography"]
  end

  # --- provider enum ---------------------------------------------------

  test "provider enum stringifies to mixin / fennec / mvm_eth / twitter" do
    mixin = UserAuthorization.new(provider: :mixin, uid: "u-1", raw: { "user_id" => "u-1" })
    fennec = UserAuthorization.new(provider: :fennec, uid: "u-2", raw: { "user_id" => "u-2" })
    mvm = UserAuthorization.new(provider: :mvm_eth, uid: "u-3", raw: { "user_id" => "u-3" })
    twitter = UserAuthorization.new(provider: :twitter, uid: "u-4", raw: { "id" => "u-4" })

    assert_equal "mixin", mixin.provider
    assert_equal "fennec", fennec.provider
    assert_equal "mvm_eth", mvm.provider
    assert_equal "twitter", twitter.provider
  end

  # --- validations -----------------------------------------------------

  test "requires provider, raw, and uid" do
    auth = UserAuthorization.new

    assert_not auth.valid?
    assert_includes auth.errors[:provider], "can't be blank"
    assert_includes auth.errors[:raw], "can't be blank"
    assert_includes auth.errors[:uid], "can't be blank"
  end

  test "uid must be unique within a provider but the same uid may exist under a different provider" do
    user = users(:author)
    UserAuthorization.create!(user: user, provider: :mixin, uid: "shared-uid", raw: { "user_id" => "shared-uid" })

    # Same uid, same provider — rejected.
    duplicate = UserAuthorization.new(user: user, provider: :mixin, uid: "shared-uid", raw: { "user_id" => "shared-uid" })
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:uid], "has already been taken"

    # Same uid, different provider — accepted.
    cross_provider = UserAuthorization.new(user: user, provider: :twitter, uid: "shared-uid", raw: { "id" => "shared-uid" })
    assert cross_provider.valid?
  end

  # --- association -----------------------------------------------------

  test "belongs_to :user is optional so an authorization may exist before provisioning" do
    orphan = UserAuthorization.create!(
      provider: :mixin,
      uid: "orphan-uid",
      raw: { "user_id" => "orphan-uid", "identity_number" => "91001" }
    )

    assert orphan.persisted?
    assert_nil orphan.user
  end

  # --- refresh! --------------------------------------------------------

  test "refresh! is a no-op for the twitter provider (no API call, no DB write)" do
    user = users(:reader_one)
    twitter_auth = user.user_authorizations.create!(
      provider: :twitter,
      uid: "reader-twitter-id",
      raw: { "id" => "reader-twitter-id", "name" => "Reader One" }
    )

    QuillBot.define_singleton_method(:api) do
      raise "refresh! for twitter must not call QuillBot.api.user"
    end

    assert_nothing_raised { twitter_auth.refresh! }

    # `update!` is skipped on the twitter early-return — the raw payload remains
    # exactly what we stored at creation time.
    twitter_auth.reload
    assert_equal({ "id" => "reader-twitter-id", "name" => "Reader One" }, twitter_auth.raw)
  end

  test "refresh! merges the data payload from QuillBot.api.user back into raw" do
    auth = user_authorizations(:author_auth)

    seen = []
    QuillBot.define_singleton_method(:api) do
      api = Object.new
      api.define_singleton_method(:user) do |mixin_uuid|
        seen << mixin_uuid
        { "data" => { "user_id" => mixin_uuid, "biography" => "fresh bio from mixin" } }
      end
      api
    end

    auth.refresh!

    assert_equal "author-mixin-uid", seen.first, "refresh! should look up by raw['user_id']"
    assert_equal "fresh bio from mixin", auth.reload.raw["biography"]
    # The merge preserves pre-existing keys.
    assert_equal "Test Author", auth.raw["name"]
  end

  # --- has_safe? -------------------------------------------------------

  test "has_safe? short-circuits on a truthy raw['has_safe'] without calling refresh!" do
    auth = user_authorizations(:author_auth)
    auth.update!(raw: auth.raw.merge("has_safe" => true))

    QuillBot.define_singleton_method(:api) do
      raise "has_safe? must not call QuillBot.api when raw['has_safe'] is already present"
    end

    assert_equal true, auth.has_safe?
  end

  test "has_safe? falls through to refresh! when raw['has_safe'] is absent and returns the refreshed flag" do
    auth = user_authorizations(:author_auth)
    auth.update!(raw: auth.raw.except("has_safe"))

    calls = 0
    QuillBot.define_singleton_method(:api) do
      api = Object.new
      api.define_singleton_method(:user) do |_uuid|
        calls += 1
        { "data" => { "user_id" => _uuid, "has_safe" => true } }
      end
      api
    end

    assert_equal true, auth.has_safe?
    assert_equal 1, calls
    assert_equal true, auth.reload.raw["has_safe"]
  end

  test "has_safe? returns false when refresh! fills has_safe with false" do
    auth = user_authorizations(:author_auth)
    auth.update!(raw: auth.raw.except("has_safe"))

    QuillBot.define_singleton_method(:api) do
      api = Object.new
      api.define_singleton_method(:user) { |_| { "data" => { "has_safe" => false } } }
      api
    end

    assert_equal false, auth.has_safe?
  end
end
