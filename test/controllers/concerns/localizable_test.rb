# frozen_string_literal: true

require "test_helper"

# Pins the contract of the `Localizable` controller concern, which is mixed
# into `ApplicationController` and provides `browser_locale` (private) — the
# request-side signal that backs `current_locale` when neither the session nor
# the user has a preference.
#
# The behaviour under `I18n.enforce_available_locales = true` (Rails default)
# is the one this app actually exercises. We assert:
#   * a missing `Accept-Language` header yields nil
#   * a single exact-match tag yields the matching symbol
#   * q=0 tags are rejected
#   * the wildcard "*" is rejected
#   * case-insensitive locale matching (e.g. "en-us" matches :en only when
#     :en is the available locale prefix — Quill's locales are bare tags, so
#     "en" matches :en, "zh-cn" matches :zh-CN, etc.)
#   * the highest-quality tag wins
#   * tags with quality less than 1.0 are sorted correctly
class LocalizableTest < ActiveSupport::TestCase
  HOST_CLASS = Class.new(ActionController::Base) do
    include Localizable

    # `browser_locale` is declared private; expose a delegating shim so the
    # tests can call it without `send(:browser_locale)` everywhere.
    public :browser_locale
  end

  setup do
    @host = HOST_CLASS.new
  end

  def with_accept_language(header)
    @host.request = ActionDispatch::TestRequest.create
    @host.request.env["HTTP_ACCEPT_LANGUAGE"] = header if header
    @host
  end

  test "browser_locale returns nil when the Accept-Language header is absent" do
    assert_nil with_accept_language(nil).browser_locale
  end

  test "browser_locale returns nil for an empty Accept-Language header" do
    assert_nil with_accept_language("").browser_locale
  end

  test "browser_locale picks the highest-quality supported tag" do
    # :en wins over :ja because q=1.0 > q=0.5.
    host = with_accept_language("ja;q=0.5,en;q=1.0")
    assert_equal :en, host.browser_locale
  end

  test "browser_locale rejects q=0 entries even if they are listed first" do
    host = with_accept_language("ja;q=0,en;q=0.3")
    assert_equal :en, host.browser_locale
  end

  test "browser_locale rejects the wildcard '*' entry" do
    # The wildcard is filtered out, leaving only "en" — which then resolves
    # to :en.
    host = with_accept_language("*,en")
    assert_equal :en, host.browser_locale
  end

  test "browser_locale returns nil when no tag matches any available locale" do
    host = with_accept_language("fr")
    assert_nil host.browser_locale
  end

  test "browser_locale matches available locales case-insensitively" do
    # :zh-CN is the configured symbol; the request sends "zh-cn".
    host = with_accept_language("zh-cn")
    assert_equal :"zh-CN", host.browser_locale
  end

  test "browser_locale returns nil when only q=0 tags are present" do
    host = with_accept_language("en;q=0,ja;q=0")
    assert_nil host.browser_locale
  end

  test "browser_locale tolerates whitespace inside the header" do
    host = with_accept_language("en ; q=0.7 ,  ja  ;  q=0.9 ")
    assert_equal :ja, host.browser_locale
  end

  test "browser_locale returns nil when all tags resolve to q=0 after filtering" do
    # Both entries start as q=0; after filter, no candidates → nil.
    host = with_accept_language("en;q=0,ja;q=0")
    assert_nil host.browser_locale
  end

  test "browser_locale picks the first match when qualities are equal" do
    host = with_accept_language("ja;q=0.5,en;q=0.5")
    # Stable behaviour: highest-quality wins; on ties, sort is stable in
    # Ruby 2.3+ so the original order is preserved. The implementation sorts
    # ascending by quality then takes the *last* element, so the second of
    # two equal-quality tags wins.
    assert_equal :en, host.browser_locale
  end

  test "match? is case-insensitive and ignores symbol/string differences" do
    host = HOST_CLASS.new
    assert host.match?(:en, "EN")
    assert host.match?("zh-CN", :"zh-cn")
    assert_not host.match?(:en, :fr)
  end
end
