# frozen_string_literal: true

require "test_helper"

class CoverArtTest < ActiveSupport::TestCase
  test "for is deterministic" do
    first = CoverArt.for("article-uuid-1")
    second = CoverArt.for("article-uuid-1")

    assert_equal first, second
  end

  test "for produces distinct art for different seeds" do
    a = CoverArt.for("seed-a")
    b = CoverArt.for("seed-b")

    refute_equal a.background, b.background
  end

  test "shapes include multiple decorative elements" do
    art = CoverArt.for("seed-shapes")

    assert art.shapes.length >= 3
    assert art.shapes.all? { |shape| CoverArt::KINDS.include?(shape.kind) }
  end

  test "background uses layered gradients" do
    art = CoverArt.for("seed-bg")

    assert_includes art.background, "radial-gradient"
    assert_includes art.background, "linear-gradient"
  end
end
