# frozen_string_literal: true

require "test_helper"

class ArticlesControllerTest < IntegrationTestCase
  test "show returns not found for missing article uuid" do
    get article_path("微信图片编辑_20240910165925")

    assert_response :not_found
  end

  test "show returns not found for spam image scan paths" do
    get "/articles/spam_scan_test.jpg"

    assert_response :not_found
  end

  test "show returns not found for draft articles" do
    article = articles(:draft)

    get user_article_path(article.author, article)

    assert_response :not_found
  end

  test "show allows guests who may buy to view paywalled article" do
    article = articles(:published_paid)

    get user_article_path(article.author, article)

    assert_response :success
    assert_match article.title, response.body
  end

  test "show succeeds for authorized buyer" do
    article = articles(:published_paid)
    buyer = users(:reader_one)

    with_quill_bot_stub do
      create_buy_order!(article: article, buyer: buyer)
    end
    sign_in(buyer)

    get user_article_path(article.author, article)

    assert_response :success
  end

  test "show renders the fade/unlock prompt for a guest viewing a locked article" do
    article = articles(:published_paid)

    get user_article_path(article.author, article)

    assert_response :success
    assert_match "data-paywall-fade-target=\"unlock\"", response.body
  end

  test "index renders a friendly, query-aware empty state for a search with no matches" do
    get articles_path(query: "no-such-article-xyz123")

    assert_response :success
    assert_match "No results for", response.body
    assert_match "no-such-article-xyz123", response.body
  end

  test "content fields partial renders lexxy editor" do
    html = ApplicationController.render(
      inline: <<~ERB,
        <%= form_for Article.new, url: '/articles' do |f| %>
          <%= render partial: 'articles/content_fields', locals: { form: f } %>
        <% end %>
      ERB
      layout: false,
    )

    assert_includes html, "<lexxy-editor"
    assert_includes html, "contentFields"
  end

  test "show succeeds for free article without login" do
    article = articles(:published_free)

    get user_article_path(article.author, article)

    assert_response :success
  end

  # Regression: after MVM login was removed, historical mvm_eth authors keep
  # Ethereum-address uids (0x…). Viewing their article from Mixin Messenger
  # used to call MixinBot::UUID.new(hex: uid) and raise InvalidUuidFormatError.
  test "show succeeds for mvm_eth author when viewed from Mixin messenger" do
    article = articles(:published_free)
    author = article.author
    author.update!(uid: "0x71f4dC846d2da8C855C61c62Ffb1997138458868")
    author.authorization.update!(provider: :mvm_eth)

    get user_article_path(author, article), headers: { "User-Agent" => "Mixin/1.0.0" }

    assert_response :success
    assert_includes response.body, "https://mixin.one/users/#{author.mixin_uuid}"
  end

  test "index succeeds when a paid article currency has a missing icon_url" do
    currency = articles(:published_paid).currency
    currency.update_column(:raw, currency.raw.except("icon_url"))

    get articles_path

    assert_response :success
  end

  test "index succeeds when a paid article currency has an invalid icon_url" do
    currency = articles(:published_paid).currency
    currency.update_column(:raw, currency.raw.merge("icon_url" => "icon_url"))

    get articles_path

    assert_response :success
  end

  # Cross-Locale Article Visibility (US5, FR-006, FR-011, SC-006):
  # Switching the visitor's preferred locale changes UI chrome (button labels,
  # navigation) but does not change the article set returned by `GET /articles`.
  # The article set must be identical before and after the locale switch.
  test "article set returned by index is stable across requests" do
    # US5 (FR-006, FR-011, SC-006): the article set returned by `GET /articles`
    # must not depend on visitor state across requests. This is the read-side
    # smoke test for "locale affects only chrome, never article visibility".
    # The locale-independent feed is exhaustively asserted at the service
    # layer in `article_search_service_test.rb`.
    get articles_path
    assert_response :success
    first = extract_article_uuids(response.body)

    get articles_path
    assert_response :success
    second = extract_article_uuids(response.body)

    refute_empty first, "expected at least one article in /articles"
    assert_equal first, second,
      "expected identical article set across two consecutive /articles requests"
  end

  test "rendered /articles page declares its html lang attribute" do
    # FR-006: the rendered chrome must declare its UI locale via the
    # `<html lang="...">` attribute. After this redesign the chrome
    # continues to render in the visitor's preferred locale, even though
    # the article set is no longer filtered by it.
    get articles_path
    assert_response :success
    assert_match(/<html\s+lang="[^"]+"/, response.body,
      "expected rendered <html lang=...> attribute on /articles")
  end

  private

  # Extract article UUIDs from the rendered /articles page by matching the
  # `/uid/uuid` link pattern that each article card renders.
  def extract_article_uuids(body)
    body.scan(%r{href="/\d+/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})"}).uniq.sort
  end
end

class ArticlesAuthenticatedControllerTest < ActionController::TestCase
  tests ArticlesController

  test "create returns json with uuid and persists tags" do
    author = users(:author)
    @request.session[:current_session_id] = sign_in(author).uuid

    assert_difference -> { author.articles.count }, 1 do
      post :create, params: {
        article: {
          title: "Autosaved draft",
          intro: "A short intro for the draft",
          content: "<p>Body content for the new article</p>",
          tag_names: %w[ruby rails]
        }
      }, format: :json
    end

    assert_response :success
    body = response.parsed_body
    assert body["uuid"].present?
    assert body["edit_path"].present?
    assert body["lock_version"].present?

    article = author.articles.find_by!(uuid: body["uuid"])
    assert_equal article.lock_version, body["lock_version"]
    assert_equal %w[rails ruby], article.tags.pluck(:name).sort
  end

  test "update accepts partial content autosave via turbo stream" do
    article = articles(:draft)
    @request.session[:current_session_id] = sign_in(article.author).uuid

    patch :update, params: {
      uuid: article.uuid,
      article: {
        title: "Updated draft title",
        lock_version: article.lock_version
      }
    }, format: :turbo_stream

    assert_response :success
    assert_equal "Updated draft title", article.reload.title
    assert_equal 1, article.lock_version
  end

  test "update returns conflict when lock_version is stale" do
    article = articles(:draft)
    @request.session[:current_session_id] = sign_in(article.author).uuid

    patch :update, params: {
      uuid: article.uuid,
      article: { title: "First save", lock_version: article.lock_version }
    }, format: :turbo_stream
    assert_response :success

    patch :update, params: {
      uuid: article.uuid,
      article: { title: "Stale save", lock_version: 0 }
    }, format: :turbo_stream

    assert_response :conflict
    assert_equal "First save", article.reload.title
  end

  test "preview shows full content for free articles" do
    article = articles(:published_free)
    @request.session[:current_session_id] = sign_in(article.author).uuid

    get :preview, params: { article_uuid: article.uuid }

    assert_response :success
    assert_match article.title, response.body
  end

  test "preview shows paywall boundary for priced articles" do
    article = articles(:published_paid)
    @request.session[:current_session_id] = sign_in(article.author).uuid

    get :preview, params: { article_uuid: article.uuid }

    assert_response :success
    assert_match article.title, response.body
  end

  test "preview is author-only" do
    article = articles(:draft)
    @request.session[:current_session_id] = sign_in(users(:reader_one)).uuid

    get :preview, params: { article_uuid: article.uuid }

    assert_response :not_found
  end

  test "update returns 409 conflict with resolution payload when lock_version is stale" do
    article = articles(:draft)
    @request.session[:current_session_id] = sign_in(article.author).uuid

    article.update!(title: "Saved by other session")

    patch :update, params: {
      uuid: article.uuid,
      article: { title: "Stale edit", lock_version: 0, content: "x" }
    }, as: :turbo_stream

    assert_response :conflict
    assert_match "conflict-resolution", response.body
  end

  test "new article page renders settings toggle button" do
    @request.session[:current_session_id] = sign_in(users(:author)).uuid

    get :new

    assert_response :success
    assert_match "settingsToggle", response.body
    assert_match "toggleSettingsRail", response.body
  end

  test "edit article page renders settings toggle and readiness indicator" do
    article = articles(:draft)
    @request.session[:current_session_id] = sign_in(article.author).uuid

    get :edit, params: { uuid: article.uuid }

    assert_response :success
    assert_match "settingsToggle", response.body
    assert_match "readinessIndicator", response.body
  end

  test "pricing section shows USD-first input" do
    article = articles(:draft)
    @request.session[:current_session_id] = sign_in(article.author).uuid

    get :edit, params: { uuid: article.uuid }

    assert_response :success
    assert_match "price_usd_input", response.body
    assert_match "setPricePreset", response.body
  end

  test "currency selection is an inline select not a modal link" do
    article = articles(:draft)
    @request.session[:current_session_id] = sign_in(article.author).uuid

    get :edit, params: { uuid: article.uuid }

    assert_response :success
    assert_match "changeCurrency", response.body
    assert_match "article_asset_id", response.body
    assert_no_match %r{href="[^"]*/currencies}, response.body
  end

  test "conflict resolution omits dismiss action" do
    article = articles(:draft)
    @request.session[:current_session_id] = sign_in(article.author).uuid

    article.update!(title: "Saved by other session")

    patch :update, params: {
      uuid: article.uuid,
      article: { title: "Stale edit", lock_version: 0, content: "x" }
    }, as: :turbo_stream

    assert_response :conflict
    assert_match "keepMyVersion", response.body
    assert_no_match "dismissConflict", response.body
  end

  test "revenue collapsed state shows default summary" do
    article = articles(:draft)
    @request.session[:current_session_id] = sign_in(article.author).uuid

    get :edit, params: { uuid: article.uuid }

    assert_response :success
    assert_match I18n.t("articles.revenue.default_summary"), response.body
  end

  test "edit page wires readiness translations" do
    article = articles(:draft)
    @request.session[:current_session_id] = sign_in(article.author).uuid

    get :edit, params: { uuid: article.uuid }

    assert_response :success
    assert_match "readiness-translations-value", response.body
    assert_match I18n.t("articles.readiness.ready"), response.body
  end

  test "revenue section has disclosure toggle" do
    article = articles(:draft)
    @request.session[:current_session_id] = sign_in(article.author).uuid

    get :edit, params: { uuid: article.uuid }

    assert_response :success
    assert_match "toggleRevenueSection", response.body
    assert_match "revenueSection", response.body
  end

  test "references section has cite-advanced disclosure toggle" do
    article = articles(:draft)
    @request.session[:current_session_id] = sign_in(article.author).uuid

    get :edit, params: { uuid: article.uuid }

    assert_response :success
    assert_match "toggleReferencesSection", response.body
    assert_match "referencesSection", response.body
  end

  test "revenue section auto-expanded for non-default values" do
    article = articles(:draft)
    article.update!(readers_revenue_ratio: 0.6, author_revenue_ratio: 0.3)
    @request.session[:current_session_id] = sign_in(article.author).uuid

    get :edit, params: { uuid: article.uuid }

    assert_response :success
    assert_match 'aria-expanded="true"', response.body
  end

  test "tag suggestions use recommended scope not unscoped" do
    @request.session[:current_session_id] = sign_in(users(:author)).uuid

    get :new

    assert_response :success
    assert_no_match "Tag.all", response.body
  end
end
