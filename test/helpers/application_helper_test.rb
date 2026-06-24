# frozen_string_literal: true

require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "remote_image_tag renders absolute urls" do
    html = remote_image_tag("https://example.com/btc.png", class: "w-6 h-6")

    assert_includes html, 'src="https://example.com/btc.png"'
    assert_includes html, 'class="w-6 h-6"'
  end

  test "remote_image_tag maps lazy to loading attribute" do
    html = remote_image_tag("https://example.com/btc.png", lazy: true)

    assert_includes html, 'loading="lazy"'
    assert_not_includes html, "lazy="
  end

  test "remote_image_tag skips blank sources" do
    assert_nil remote_image_tag(nil)
    assert_nil remote_image_tag("")
  end

  test "remote_image_tag skips non-url asset-like sources" do
    assert_nil remote_image_tag("icon_url")
  end
end
