# frozen_string_literal: true

require "application_system_test_case"

class ArticlePaywallTest < ApplicationSystemTestCase
  # :selenium (the class default) needs a real Chrome install; this suite only
  # asserts on server-rendered markup, so the JS-free :rack_test driver keeps
  # it runnable without a browser.
  driven_by :rack_test

  include CommerceHelpers
  include QuillBotStub

  test "guest can view paid article page with title" do
    article = articles(:published_paid)

    visit user_article_path(article.author, article)

    assert_text article.title
  end

  test "locked article fades into an unlock prompt for a guest who hasn't purchased" do
    article = articles(:published_paid)

    visit user_article_path(article.author, article)

    assert_selector "[data-paywall-fade-target='unlock']"
  end

  test "free article renders no unlock prompt" do
    article = articles(:published_free)

    visit user_article_path(article.author, article)

    assert_no_selector "[data-paywall-fade-target='unlock']"
  end
end
