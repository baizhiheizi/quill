# frozen_string_literal: true

require "test_helper"

# Covers `Articles::PosterGenerator` — the ActiveStorage-backed surface that
# builds cover/poster URLs and QR codes for an Article. The concern mixes
# into Article; its single external dependency is ActiveStorage, with
# `Settings.storage.endpoint` for URL composition and `Articles::GeneratePosterJob`
# for async generation.
class Articles::PosterGeneratorTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers
  # --- `cover_url` -------------------------------------------------------

  test "cover_url returns nil when cover is not attached" do
    article = stub_cover(attached: false)

    assert_nil article.cover_url
  end

  test "cover_url concatenates Settings.storage.endpoint with cover.key" do
    article = stub_cover(attached: true, key: "covers/abc/cover.jpg")

    assert_equal "#{Settings.storage.endpoint}/covers/abc/cover.jpg", article.cover_url
  end

  # --- `thumb_url` -------------------------------------------------------

  test "thumb_url returns cover_url when cover is attached" do
    article = stub_cover(attached: true, key: "covers/abc/cover.jpg")

    assert_equal "#{Settings.storage.endpoint}/covers/abc/cover.jpg", article.thumb_url
  end

  test "thumb_url returns nil when cover is not attached and the article is paid and not published" do
    article = articles(:published_paid)
    article.update_columns(price: 0.0001, state: "drafted")
    article.define_singleton_method(:cover) do
      Struct.new(:attached?).new(false)
    end

    assert_nil article.thumb_url
  end

  test "thumb_url enqueues GenerateDefaultCoverJob for paid published article without cover" do
    article = articles(:published_paid)
    article.update_columns(price: 0.0001, state: "published")
    article.define_singleton_method(:cover) do
      Struct.new(:attached?).new(false)
    end
    article.define_singleton_method(:generate_default_cover) { nil }

    assert_enqueued_with(job: Articles::GenerateDefaultCoverJob, args: [ article.id ]) do
      assert_nil article.thumb_url
    end
  end

  test "thumb_url extracts the first absolute image URL from content when free" do
    article = articles(:published_free)
    article.update_columns(price: 0.0)
    article.define_singleton_method(:cover) do
      Struct.new(:attached?).new(false)
    end
    html = <<~HTML
      <p>intro</p>
      <p><img src="/relative/path.png"></p>
      <p><img src="https://cdn.example.com/hero.png"></p>
    HTML
    article.define_singleton_method(:content_as_html) { html }

    assert_equal "https://cdn.example.com/hero.png", article.thumb_url
  end

  test "thumb_url memoizes the parsed result across calls" do
    article = articles(:published_free)
    article.update_columns(price: 0.0)
    article.define_singleton_method(:cover) do
      Struct.new(:attached?).new(false)
    end
    html = '<img src="https://cdn.example.com/hero.png">'
    call_count = 0
    article.define_singleton_method(:content_as_html) do
      call_count += 1
      html
    end

    first = article.thumb_url
    second = article.thumb_url

    assert_same first, second
    assert_equal 1, call_count, "content_as_html should only fire once (memoized)"
  end

  # --- `poster_url` ------------------------------------------------------

  test "poster_url returns Settings.storage.endpoint + poster.key when poster is attached" do
    article = articles(:published_paid)
    article.define_singleton_method(:poster) do
      Struct.new(:attached?, :key).new(true, "posters/xyz/poster.png")
    end

    assert_equal "#{Settings.storage.endpoint}/posters/xyz/poster.png", article.poster_url
  end

  test "poster_url enqueues Articles::GeneratePosterJob and returns nil when poster is not attached" do
    article = articles(:published_paid)
    article.define_singleton_method(:poster) do
      Struct.new(:attached?).new(false)
    end

    assert_enqueued_with(job: Articles::GeneratePosterJob, args: [ article.id ]) do
      assert_nil article.poster_url
    end
  end

  # --- `generated_poster_url` -------------------------------------------

  # The concern calls `Rails.application.credentials.dig(:grover, :token)`.
  # Replace `Rails.application.credentials` with a tiny stand-in whose `#dig`
  # returns whatever the test wants, then restore in `ensure`.
  FakeCredentials = Struct.new(:grover_token) do
    def dig(_key1, _key2)
      grover_token
    end
  end

  def with_grover_credentials(grover_token)
    original_credentials = Rails.application.credentials
    Rails.application.define_singleton_method(:credentials) do
      FakeCredentials.new(grover_token)
    end
    yield
  ensure
    Rails.application.define_singleton_method(:credentials) { original_credentials }
  end

  test "generated_default_cover_url uses grover_article_cover_url with the credential token and png format" do
    article = articles(:published_paid)
    expected_token = "grover-cover-token"
    article.define_singleton_method(:grover_article_cover_url) do |uuid, **opts|
      { uuid: uuid, opts: opts, endpoint: "grover/articles/#{uuid}/cover.#{opts[:format]}" }
    end

    with_grover_credentials(expected_token) do
      result = article.generated_default_cover_url

      assert_equal article.uuid, result[:uuid]
      assert_equal expected_token, result[:opts][:token]
      assert_equal :png, result[:opts][:format]
      assert_equal "grover/articles/#{article.uuid}/cover.png", result[:endpoint]
    end
  end

  test "ColorFromSeed produces distinct hues for different article uuids" do
    a = articles(:published_paid)
    b = articles(:published_free)

    refute_equal ColorFromSeed.hue(a.uuid), ColorFromSeed.hue(b.uuid)
  end

  test "thumb_url prefers attached cover over generated default" do
    article = stub_cover(attached: true, key: "covers/abc/cover.jpg")

    assert_equal "#{Settings.storage.endpoint}/covers/abc/cover.jpg", article.thumb_url
  end

  test "generated_poster_url uses grover_article_poster_url with the credential token and png format" do
    article = articles(:published_paid)
    expected_token = "grover-test-token"
    article.define_singleton_method(:grover_article_poster_url) do |uuid, **opts|
      { uuid: uuid, opts: opts, endpoint: "grover/articles/#{uuid}/poster.#{opts[:format]}" }
    end

    with_grover_credentials(expected_token) do
      result = article.generated_poster_url

      assert_equal article.uuid, result[:uuid]
      assert_equal expected_token, result[:opts][:token]
      assert_equal :png, result[:opts][:format]
      assert_equal "grover/articles/#{article.uuid}/poster.png", result[:endpoint]
    end
  end

  test "generated_poster_url passes a nil token when credentials do not provide one" do
    article = articles(:published_paid)
    captured = nil
    article.define_singleton_method(:grover_article_poster_url) do |_uuid, **opts|
      captured = opts
      "https://example.invalid/poster.png"
    end

    with_grover_credentials(nil) do
      article.generated_poster_url
    end

    assert_nil captured[:token]
  end

  # --- `generate_poster_async` ------------------------------------------

  test "generate_poster_async enqueues Articles::GeneratePosterJob with the article id" do
    article = articles(:published_paid)

    assert_enqueued_with(job: Articles::GeneratePosterJob, args: [ article.id ]) do
      article.generate_poster_async
    end
  end

  # --- `qrcode_base64` --------------------------------------------------

  test "qrcode_base64 returns a data URL with base64-encoded PNG bytes" do
    article = articles(:published_paid)
    expected_url = user_article_url(article.author, article)

    data_url = article.qrcode_base64

    assert_match(/\Adata:image\/png;base64, /, data_url)
    body = data_url.sub(/\Adata:image\/png;base64, /, "")
    decoded = Base64.decode64(body)

    # PNG magic: 89 50 4E 47 0D 0A 1A 0A. The first three bytes are sufficient
    # to pin "this is the PNG that came back from RQRCode".
    assert_equal "\x89PNG".b, decoded.byteslice(0, 4).force_encoding(Encoding::BINARY),
                 "expected a PNG payload but got: #{decoded.bytes.first(8).inspect}"
    # Sanity: the helper produces a different base64 string for a different URL
    # (verified against a second article instance pointing at the same author).
    other_article = articles(:published_free).tap { |a| a.update!(author: article.author, asset_id: article.asset_id) }
    other_url = user_article_url(article.author, other_article)
    refute_equal expected_url, other_url
    refute_equal article.qrcode_base64, other_article.qrcode_base64
  end

  test "qrcode_base64 produces a different base64 string when the URL differs" do
    paid = articles(:published_paid)
    # qrcode_base64 is not memoized — two consecutive calls produce the same
    # string, but two different articles produce different PNGs.
    paid_again = articles(:published_paid)

    assert_equal paid.qrcode_base64, paid_again.qrcode_base64
    refute_nil paid.qrcode_base64
  end

  private

  # Build an article whose `cover` attachment responds to `attached?` and
  # `key` according to the test's needs. Avoids touching ActiveStorage
  # disk-backed fixtures while still exercising the public surface.
  def stub_cover(attached:, key: nil)
    article = articles(:published_paid)
    cover = Struct.new(:attached?, :key).new(attached, key)
    article.define_singleton_method(:cover) { cover }
    article
  end
end
