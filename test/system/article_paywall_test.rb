# frozen_string_literal: true

require "application_system_test_case"

class ArticlePaywallTest < ApplicationSystemTestCase
  include CommerceHelpers
  include QuillBotStub

  test "guest can view paid article page with title" do
    article = articles(:published_paid)

    visit user_article_path(article.author, article)

    assert_text article.title
  end
end
