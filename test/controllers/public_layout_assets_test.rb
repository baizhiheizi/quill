# frozen_string_literal: true

require "test_helper"

class PublicLayoutAssetsTest < IntegrationTestCase
  test "articles index does not block first paint on Google Fonts or GTM" do
    get articles_path

    assert_response :success
    refute_match %r{fonts\.googleapis\.com}, response.body
    refute_match %r{fonts\.gstatic\.com}, response.body
    refute_match %r{<script[^>]+src=["']https://www\.googletagmanager\.com}, response.body
    assert_match(/requestIdleCallback/, response.body)
    assert_match(/G-TNT4ZMVDL4/, response.body)
    assert_match(/inter-latin-400-normal/, response.body)
    assert_match(/newsreader-latin-600-normal/, response.body)
    assert_includes response.body, 'defer="defer"'
    assert_match(/application[^"]*\.js/, response.body)
  end

  test "desktop landing page self-hosts fonts and defers application.js" do
    get root_path

    assert_response :success
    refute_match %r{fonts\.googleapis\.com}, response.body
    assert_match(/inter-latin-400-normal/, response.body)
    assert_includes response.body, 'defer="defer"'
  end
end
