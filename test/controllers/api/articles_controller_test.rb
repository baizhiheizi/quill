# frozen_string_literal: true

require "test_helper"

class API::ArticlesControllerTest < IntegrationTestCase
  test "show returns 404 for draft without auth" do
    article = articles(:draft)

    get api_article_path(article.uuid), as: :json

    assert_response :not_found
  end

  test "show omits content for unauthorized requests" do
    article = articles(:published_paid)

    get api_article_path(article.uuid), as: :json

    assert_response :success
    body = response.parsed_body
    assert_nil body["content"]
    assert_equal article.uuid, body["uuid"]
  end

  test "show includes content for authorized token" do
    article = articles(:published_paid)
    buyer = users(:reader_one)

    with_quill_bot_stub do
      create_buy_order!(article: article, buyer: buyer)
    end

    get api_article_path(article.uuid), headers: api_headers(access_tokens(:reader_token)), as: :json

    assert_response :success
    assert_equal article.content, response.parsed_body["content"]
  end
end
