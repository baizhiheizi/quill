# frozen_string_literal: true

require "test_helper"

# Direct coverage of `ColorFromSeed` (FNV-1a 32-bit → hue → CSS).
# Mirrors `app/javascript/utils/avatar.js` (`fnv1aHash` / `colorFromSeed`).
# Canonical 32-bit FNV-1a vectors: IETF / Fowler (empty, "a", "foobar").
class ColorFromSeedTest < ActiveSupport::TestCase
  # https://datatracker.ietf.org/doc/html/draft-eastlake-fnv-17#name-fnv-test-vectors
  FNV1A_32_VECTORS = {
    "" => 0x811c9dc5,
    "a" => 0xe40c292c,
    "foobar" => 0xbf9cf968
  }.freeze

  test "fnv1a_hash matches the 32-bit FNV-1a canonical test vectors" do
    FNV1A_32_VECTORS.each do |seed, expected|
      assert_equal expected, ColorFromSeed.fnv1a_hash(seed),
        "FNV-1a(#{seed.inspect}) should be 0x#{expected.to_s(16)}"
    end
  end

  test "fnv1a_hash is deterministic" do
    assert_equal ColorFromSeed.fnv1a_hash("quill"), ColorFromSeed.fnv1a_hash("quill")
  end

  test "fnv1a_hash coerces nil Integer and Symbol seeds via String()" do
    assert_equal ColorFromSeed.fnv1a_hash(""), ColorFromSeed.fnv1a_hash(nil)
    assert_equal ColorFromSeed.fnv1a_hash("123"), ColorFromSeed.fnv1a_hash(123)
    assert_equal ColorFromSeed.fnv1a_hash("foo"), ColorFromSeed.fnv1a_hash(:foo)
  end

  test "hue is hash modulo 360 and stays in [0, 360)" do
    FNV1A_32_VECTORS.each_key do |seed|
      value = ColorFromSeed.hue(seed)

      assert_equal ColorFromSeed.fnv1a_hash(seed) % 360, value
      assert_operator value, :>=, 0
      assert_operator value, :<, 360
    end
  end

  test "hue remains in [0, 360) for nil Integer and Symbol seeds" do
    [ nil, 0, 123, :author ].each do |seed|
      value = ColorFromSeed.hue(seed)

      assert_operator value, :>=, 0
      assert_operator value, :<, 360
    end
  end

  test "hsl formats hue with default saturation and lightness" do
    assert_equal "hsl(61, 65%, 45%)", ColorFromSeed.hsl("")
    assert_equal "hsl(340, 65%, 45%)", ColorFromSeed.hsl("a")
  end

  test "hsl accepts custom saturation and lightness" do
    assert_equal "hsl(61, 80%, 30%)", ColorFromSeed.hsl("", saturation: 80, lightness: 30)
  end

  test "gradient_css is a 135deg two-stop linear-gradient" do
    css = ColorFromSeed.gradient_css("")

    assert_equal "linear-gradient(135deg, hsl(61, 65%, 45%), hsl(101, 55%, 35%))", css
  end

  test "gradient_css wraps the second stop hue into [0, 360)" do
    # hue("a") is 340; 340 + 40 = 380 → 20
    css = ColorFromSeed.gradient_css("a")

    assert_equal "linear-gradient(135deg, hsl(340, 65%, 45%), hsl(20, 55%, 35%))", css
  end

  test "hsl matches the JS colorFromSeed format used by avatar.js" do
    # app/javascript/utils/avatar.js:
    #   `hsl(${fnv1aHash(String(seed || "")) % 360}, 65%, 45%)`
    seed = "a1111111-1111-4111-8111-111111111111"
    hue = ColorFromSeed.hue(seed)

    assert_equal "hsl(#{hue}, 65%, 45%)", ColorFromSeed.hsl(seed)
  end
end
