# frozen_string_literal: true

require "test_helper"

# Covers the `AdvisoryLockable` concern, which is mixed into `Splitter` and
# `MixinNetworkUser` (and any future model that opts in via
# `include AdvisoryLockable`). The concern wraps a block in a PostgreSQL
# advisory lock keyed by a SHA-256 hash of the caller's key string.
#
# Two surfaces are exercised:
#   * `AdvisoryLockable.lock_id_for(key)` is a pure function — same key
#     always yields the same BigInt-shaped signed 63-bit integer, distinct
#     keys never collide, and non-string keys coerce via `to_s`.
#   * `with_advisory_lock(key, &block)` is exercised end-to-end through the
#     existing `Splitter#collect_assets` path (`test/models/splitter_test.rb`
#     already stubs the lock branches). This file pins the concern's pure
#     surface and the lock_id-for-key contract so a regression here surfaces
#     independently of Splitter's transfer-creation side effects.
class AdvisoryLockableTest < ActiveSupport::TestCase
  # ---------------------------------------------------------------------------
  # lock_id_for — pure-function surface
  # ---------------------------------------------------------------------------

  test "lock_id_for is deterministic for the same key" do
    key = "splitter:42:collect"
    assert_equal AdvisoryLockable.lock_id_for(key), AdvisoryLockable.lock_id_for(key)
  end

  test "lock_id_for returns a signed 63-bit integer (PostgreSQL bigint range)" do
    [ "foo", "splitter:1:collect", "mixin_user:uuid:pin_update", SecureRandom.hex ].each do |key|
      id = AdvisoryLockable.lock_id_for(key)

      assert_kind_of Integer, id
      assert id >= -(2**63), "lock_id for #{key.inspect} underflowed the signed 63-bit range"
      assert id < 2**63,    "lock_id for #{key.inspect} overflowed the signed 63-bit range"
    end
  end

  test "lock_id_for produces distinct values for distinct keys" do
    a = AdvisoryLockable.lock_id_for("alpha")
    b = AdvisoryLockable.lock_id_for("beta")
    c = AdvisoryLockable.lock_id_for("alpha:1")
    d = AdvisoryLockable.lock_id_for("alpha:2")

    assert_not_equal a, b
    assert_not_equal c, d
    assert_not_equal a, c
    assert_not_equal b, c
  end

  test "lock_id_for coerces non-string keys via to_s" do
    sym = AdvisoryLockable.lock_id_for(:foo)
    str = AdvisoryLockable.lock_id_for("foo")

    assert_equal str, sym
  end

  test "lock_id_for treats nil as the empty string" do
    # The concern uses `key.to_s` so nil maps to "". We pin that behaviour
    # here — a future refactor that special-cases nil would change this test.
    assert_equal AdvisoryLockable.lock_id_for(""), AdvisoryLockable.lock_id_for(nil)
  end
end
