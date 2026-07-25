# frozen_string_literal: true

require "test_helper"

class LocalesControllerTest < ActionController::TestCase
  tests LocalesController

  setup do
    @request.session[:session_id] = "test"
  end

  test "locale route compiles to a single valid regex (defensive)" do
    # The route defined in config/routes.rb must survive a full route-table
    # compile plus a recognize_path round-trip. The pre-fix form used
    # `I18n.available_locales.map(&:to_s)` which silently emitted a broken
    # array constraint; this test pins the fix in place.
    assert_nothing_raised do
      Rails.application.routes.recognize_path("/en", method: :get)
    end
    assert_nothing_raised do
      Rails.application.routes.recognize_path("/zh-CN", method: :get)
    end
    assert_nothing_raised do
      Rails.application.routes.recognize_path("/ja", method: :get)
    end
  end

  test "show processes :show via direct invocation without a RegexpError" do
    # This is the path that previously failed with
    # `RegexpError: empty range in char class: /\A["en", "zh-CN", "ja"]\Z/`
    # because Journey's `requirements_for_missing_keys_check` interpolates
    # the constraint value verbatim. After the fix, the value is a Regexp
    # (`/en|zh\-CN|ja/`) and interpolation uses the regex source.
    assert_nothing_raised do
      process :show, method: "GET", params: { locale: "en" }
    end
    assert_includes [ 302, 301 ], @response.status
  end

  test "show redirects to safe_return_to when locale is recognised" do
    process :show, method: "GET", params: { locale: "en", return_to: "/articles/foo" }
    assert_includes [ 302, 301 ], @response.status
    assert_match %r{/articles/foo}, @response.location.to_s
  end

  test "show falls back to root_path when no return_to is provided" do
    process :show, method: "GET", params: { locale: "en" }
    assert_includes [ 302, 301 ], @response.status
    assert_match %r{\Ahttp://test\.host/}, @response.location.to_s
  end

  test "show persists valid locale string into session" do
    process :show, method: "GET", params: { locale: "zh-CN" }
    assert_equal "zh-CN", @request.session[:current_locale]
  end

  test "show ignores an unsupported locale (klingon)" do
    @request.session[:current_locale] = "en"
    # Bypass the route guard via :create, which lacks a constraint on locale.
    process :create, method: "POST", params: { locale: "klingon" }
    assert_equal "en", session[:current_locale]
  end

  test "edit renders the locales#edit view" do
    get :edit
    assert_response :success
    assert_match %r{<html|<body|<form|<select}, @response.body.to_s
  end

  test "create persists the ja locale and redirects home" do
    post :create, params: { locale: "ja" }
    assert_equal "ja", @request.session[:current_locale]
    assert_redirected_to root_path
  end

  test "create rejects an unsupported locale" do
    post :create, params: { locale: "klingon" }
    assert_nil @request.session[:current_locale]
    assert_redirected_to root_path
  end

  test "create ignores missing locale param" do
    post :create, params: {}
    assert_nil @request.session[:current_locale]
  end
end
