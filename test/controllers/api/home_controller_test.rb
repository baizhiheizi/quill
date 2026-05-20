# frozen_string_literal: true

require "test_helper"

class API::HomeControllerTest < IntegrationTestCase
  test "GET api article show returns success for free article" do
    article = articles(:published_free)

    get api_article_path(article.uuid), as: :json

    assert_response :success
    assert_equal article.uuid, response.parsed_body["uuid"]
  end
end
