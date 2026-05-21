# frozen_string_literal: true

require "test_helper"

class SessionsControllerTest < IntegrationTestCase
  test "mvm callback rejects external return_to URLs" do
    get auth_mvm_callback_path, params: {
      address: "0x0",
      signature: "invalid",
      return_to: "https://evil.com/phish"
    }

    assert_redirected_to root_path
  end

  test "mvm callback allows same-host return_to URLs" do
    article = articles(:published_free)

    get auth_mvm_callback_path, params: {
      address: "0x0",
      signature: "invalid",
      return_to: user_article_url(article.author, article)
    }

    assert_redirected_to user_article_url(article.author, article)
  end
end
