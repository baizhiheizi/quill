# frozen_string_literal: true

require "test_helper"

class ShareHelperTest < ActionView::TestCase
  include QuillBotStub

  test "share_to_twitter builds an intent URL with text, url, and via" do
    url = share_to_twitter("https://example.com/post", "Hello world", "quill")

    assert_equal(
      "https://twitter.com/intent/tweet?text=Hello%20world" \
        "&url=https%3A%2F%2Fexample.com%2Fpost" \
        "&via=quill",
      url
    )
  end

  test "share_to_twitter falls back to Settings.twitter_account when via is omitted" do
    url = share_to_twitter("https://example.com", "x")

    assert_includes url, "&via=#{Settings.twitter_account}"
  end

  test "share_to_telegram builds a share URL with url and text" do
    url = share_to_telegram("https://example.com/post", "Hello world")

    assert_equal(
      "https://t.me/share/url?url=https%3A%2F%2Fexample.com%2Fpost" \
        "&text=Hello%20world",
      url
    )
  end

  test "share_to_mixin builds a base64-encoded app card payload" do
    with_quill_bot_stub do
      url = share_to_mixin(
        "https://example.com/post",
        title: "A long article title that exceeds the thirty-six character cap",
        description: "An article description used for the share card preview, padded out with extra prose so it crosses the 128-character cap that the Mixin share card imposes on the description field for the app card preview that we render for the reader.",
        icon_url: "https://example.com/icon.png"
      )

      assert url.start_with?("mixin://send?category=app_card&data=")
      payload = url.split("data=", 2).last
      decoded = JSON.parse(Base64.strict_decode64(CGI.unescape(payload)))

      assert_equal "https://example.com/post", decoded["action"]
      assert_equal QuillBotStub::FAKE_CLIENT_ID, decoded["app_id"]
      assert_equal 36, decoded["title"].length
      assert_equal "A long article title that exceeds...", decoded["title"]
      assert_equal 128, decoded["description"].length
      assert_equal "https://example.com/icon.png", decoded["icon_url"]
    end
  end

  test "share_to_mixin leaves shorter title and description untouched" do
    with_quill_bot_stub do
      url = share_to_mixin(
        "https://example.com",
        title: "Short",
        description: "Also short",
        icon_url: "https://example.com/icon.png"
      )

      payload = url.split("data=", 2).last
      decoded = JSON.parse(Base64.strict_decode64(CGI.unescape(payload)))

      assert_equal "Short", decoded["title"]
      assert_equal "Also short", decoded["description"]
    end
  end
end
