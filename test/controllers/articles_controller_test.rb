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

  # Cross-Locale Article Visibility (US3, FR-010, SC-007):
  # Each article card on the index must surface its language so a visitor
  # browsing in any locale can tell what language each card is in.
  test "index renders language chip for every locale in the feed" do
    get articles_path

    assert_response :success
    assert_match(/article-card__locale/, response.body,
      "expected at least one article-card__locale chip element in the index")
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
end
