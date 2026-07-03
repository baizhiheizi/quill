# frozen_string_literal: true

require "test_helper"

class Admin::ArticlesControllerTest < ActionController::TestCase
  tests Admin::ArticlesController

  setup do
    @admin = administrators(:one)
    # `Admin::BaseController#authenticate_admin!` only checks
    # `current_admin.blank?`. We bypass it by setting the session directly.
    @request.session[:current_admin_id] = @admin.id
  end

  # Cross-Locale Article Visibility (US4, FR-008, SC-004):
  # The admin articles index must keep filtering by `articles.locale` per
  # the `EN / ZH / JA / Others` dropdown. This is a regression test that
  # pins the admin behavior — the redesign only changes visitor-facing
  # surfaces, not back-office tooling.
  test "admin locale filter narrows the index to articles matching the chosen locale" do
    %w[en zh ja].each do |locale|
      get :index, params: { locale: locale }

      assert_response :success
      result = @controller.instance_variable_get(:@articles).to_a

      result.each do |article|
        assert_equal locale, article.locale,
          "expected locale=#{locale} filter to only return matching articles, got #{article.locale} for article #{article.uuid}"
      end
    end
  end

  test "admin locale filter 'others' returns articles whose locale is not en/zh/ja" do
    # Create an article with an 'others' locale for the assertion to be meaningful.
    article = articles(:high_revenue)
    article.update_column(:locale, "ko")

    get :index, params: { locale: "others" }

    assert_response :success
    result = @controller.instance_variable_get(:@articles).to_a

    assert_predicate result, :any?,
      "expected at least one article in 'others' (locale='ko'), got: #{result.map(&:locale).inspect}"

    result.each do |a|
      assert_not_includes %w[en zh ja], a.locale,
        "expected 'others' to exclude en/zh/ja articles, got #{a.locale}"
    end
  end

  test "admin locale filter 'all' returns articles regardless of locale" do
    get :index, params: { locale: "all" }

    assert_response :success
    result = @controller.instance_variable_get(:@articles).to_a

    locales = result.map(&:locale).uniq
    assert_operator locales.size, :>=, 2,
      "expected 'all' to return articles across multiple locales, got: #{locales.inspect}"
    assert_includes locales, "en"
    assert_includes locales, "zh"
    assert_includes locales, "ja"
  end
end
