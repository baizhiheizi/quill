# frozen_string_literal: true

require "test_helper"

class ArticlesControllerTest < IntegrationTestCase
  test "show redirects for draft articles" do
    article = articles(:draft)

    get user_article_path(article.author, article)

    assert_response :redirect
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
end
