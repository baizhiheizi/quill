# frozen_string_literal: true

require "test_helper"

class PublicLayoutAssetsTest < IntegrationTestCase
  test "articles index does not block first paint on Google Fonts or load GTM" do
    get articles_path

    assert_response :success
    refute_match %r{fonts\.googleapis\.com}, response.body
    refute_match %r{fonts\.gstatic\.com}, response.body
    refute_match %r{googletagmanager\.com}, response.body
    refute_match(/G-TNT4ZMVDL4/, response.body)
    assert_match(/inter-latin-400-normal/, response.body)
    assert_match(/newsreader-latin-600-normal/, response.body)
    assert_includes response.body, 'defer="defer"'
    assert_match(/application[^"]*\.js/, response.body)
    assert_match(%r{assets/reader[^"]*\.js}, response.body)
    refute_match(%r{assets/editor[^"]*\.js}, response.body)
  end

  test "desktop landing page self-hosts fonts and skips reader/editor bundles" do
    get root_path

    assert_response :success
    refute_match %r{fonts\.googleapis\.com}, response.body
    assert_match(/inter-latin-400-normal/, response.body)
    assert_match(/rel="preload"[^>]+inter-latin-400-normal/, response.body)
    assert_match(/rel="preload"[^>]+inter-latin-500-normal/, response.body)
    assert_match(/rel="preload"[^>]+newsreader-latin-500-normal/, response.body)
    assert_includes response.body, 'defer="defer"'
    assert_match(/application[^"]*\.js/, response.body)
    refute_match(%r{assets/reader}, response.body)
    refute_match(%r{assets/editor}, response.body)
  end

  test "desktop landing page inlines discovery frames and sizes the logo" do
    get root_path

    assert_response :success
    assert_select "turbo-frame#selected_articles:not([src])"
    assert_select "turbo-frame#active_authors:not([src])"
    assert_select "turbo-frame#hot_tags:not([src])"
    assert_select "img[alt=Quill][width][height]"
  end
end
