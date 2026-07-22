# frozen_string_literal: true

require "application_system_test_case"

class ArticleEditorTest < ApplicationSystemTestCase
  # Markup/structure assertions only — :selenium needs Chrome; rack_test stays CI-friendly.
  # Use page.driver.visit to avoid turbo-rails cable-stream connect helpers under rack_test.
  driven_by :rack_test

  include CommerceHelpers
  include QuillBotStub

  setup do
    @author = users(:author)
    @session_record = Session.create!(
      user: @author,
      uuid: SecureRandom.uuid,
      info: { "provider" => "mixin" }
    )

    @original_current_session = ApplicationController.instance_method(:current_session)
    @original_current_user = ApplicationController.instance_method(:current_user)
    @original_authenticate_user = ApplicationController.instance_method(:authenticate_user!)

    session_record = @session_record
    ApplicationController.define_method(:current_session) { session_record }
    ApplicationController.define_method(:current_user) { session_record.user }
    ApplicationController.define_method(:authenticate_user!) { true }
  end

  teardown do
    ApplicationController.define_method(:current_session, @original_current_session)
    ApplicationController.define_method(:current_user, @original_current_user)
    ApplicationController.define_method(:authenticate_user!, @original_authenticate_user)
  end

  test "guest visiting new article is redirected to login" do
    ApplicationController.define_method(:current_session, @original_current_session)
    ApplicationController.define_method(:current_user, @original_current_user)
    ApplicationController.define_method(:authenticate_user!, @original_authenticate_user)

    page.driver.visit new_article_path

    assert_operator page.status_code, :<, 400
  end

  test "editor shows only title intro content by default" do
    page.driver.visit new_article_path

    assert_equal 200, page.status_code
    assert_selector "#article_title"
    assert_selector "#article_intro"
    assert_selector "[data-article-form-target='settingsRail']", visible: :all
    assert_no_selector ".article-editor--settings-open"
    assert_selector "[data-article-form-target='settingsToggle']"
  end

  test "settings panel toggle wiring is present" do
    page.driver.visit new_article_path

    toggle = find("[data-article-form-target='settingsToggle']", visible: :all)
    assert_equal "article-form#toggleSettingsRail", toggle["data-action"]
    assert_equal "false", toggle["aria-expanded"]
  end

  test "usd price input and presets are present in settings markup" do
    page.driver.visit edit_article_path(articles(:draft).uuid)

    assert_selector "[data-article-form-target='priceUsdInput']", visible: :all
    assert_selector "[data-action='article-form#setPricePreset']", visible: :all, minimum: 4
    assert_selector "[data-article-form-target='priceCryptoDisplay']", visible: :all
    assert_includes page.html, "price_usd_input"
  end

  test "price formatting uses two decimal presets" do
    page.driver.visit edit_article_path(articles(:draft).uuid)

    assert_selector "[data-article-form-preset-param='0.5']", visible: :all
    assert_selector "[data-article-form-preset-param='1']", visible: :all
    assert_selector "[data-article-form-preset-param='2']", visible: :all
    assert_selector "[data-article-form-preset-param='5']", visible: :all
  end

  test "currency uses inline select not modal grid" do
    page.driver.visit edit_article_path(articles(:draft).uuid)

    assert_selector "select#article_asset_id[data-action='change->article-form#changeCurrency']", visible: :all
    assert_no_selector "a[data-turbo-frame='modal'][href*='currencies']", visible: :all
  end

  test "intro textarea auto-resize controller is wired" do
    page.driver.visit new_article_path

    intro = find("#article_intro", visible: :all)
    assert_includes intro["data-controller"].to_s, "textarea"
    assert_includes intro["data-action"].to_s, "textarea#resize"
  end

  test "conflict resolution payload offers keep my version without dismiss" do
    article = articles(:draft)
    article.update!(title: "Saved by other session")

    page.driver.header "Accept", "text/vnd.turbo-stream.html, text/html, application/xhtml+xml"
    page.driver.submit :patch, article_path(article.uuid), {
      "article[title]" => "Stale edit",
      "article[lock_version]" => "0",
      "article[content]" => "x"
    }

    body = page.driver.response.body
    assert_includes body, "conflict-resolution"
    assert_includes body, "article-form#keepMyVersion"
    assert_includes body, I18n.t("articles.conflict.reload_latest")
    assert_not_includes body, "article-form#dismissConflict"
  end

  test "revenue section collapsed by default" do
    page.driver.visit edit_article_path(articles(:draft).uuid)

    assert_includes page.html, I18n.t("articles.revenue.customize")
    assert_includes page.html, I18n.t("articles.revenue.default_summary")
    section = find("[data-article-revenue-target='revenueSection']", visible: :all)
    assert_includes section[:class], "hidden"
  end

  test "revenue expands markup includes ratio fields" do
    page.driver.visit edit_article_path(articles(:draft).uuid)

    assert_selector "#article_readers_revenue_ratio", visible: :all
    assert_selector "#article_author_revenue_ratio", visible: :all
    assert_selector "[data-action='article-revenue#toggleRevenueSection']", visible: :all
  end

  test "references collapsed by default" do
    page.driver.visit edit_article_path(articles(:draft).uuid)

    assert_includes page.html, "Cite articles"
    assert_selector "[data-action='article-revenue#toggleReferencesSection']", visible: :all
    refs = find("[data-article-revenue-target='referencesSection']", visible: :all)
    assert_includes refs[:class], "hidden"
  end

  test "readiness indicator and translations are present on edit" do
    page.driver.visit edit_article_path(articles(:draft).uuid)

    assert_selector "[data-article-form-target='readinessIndicator']", visible: :all
    assert_includes page.html, "readiness-translations-value"
    assert_includes page.html, I18n.t("articles.readiness.ready")
  end

  test "readiness translations include things to fix template" do
    page.driver.visit edit_article_path(articles(:draft).uuid)

    assert_includes page.html, "%{count}"
    assert_includes page.html, "%{thing}"
  end
end
