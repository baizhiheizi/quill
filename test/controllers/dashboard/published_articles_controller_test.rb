# frozen_string_literal: true

require "test_helper"

class Dashboard::PublishedArticlesControllerTest < ActionController::TestCase
  tests Dashboard::PublishedArticlesController

  test "new shows readiness errors for incomplete article" do
    article = articles(:draft)
    article.update_columns(title: "", intro: "")
    @request.session[:current_session_id] = sign_in(article.author).uuid

    get :new, params: { uuid: article.uuid }

    assert_response :success
    assert_match I18n.t("articles.publish_blocked"), response.body
    assert_match "Please input your post", response.body
  end

  test "new shows ready confirmation for valid article" do
    article = articles(:draft)
    article.content = "<p>Enough content to publish</p>"
    article.save!
    @request.session[:current_session_id] = sign_in(article.author).uuid

    get :new, params: { uuid: article.uuid }

    assert_response :success
    assert_match I18n.t("articles.publish_ready"), response.body
  end

  test "update publishes a valid draft" do
    article = articles(:draft)
    article.content = "<p>Enough content to publish</p>"
    article.save!
    @request.session[:current_session_id] = sign_in(article.author).uuid

    put :update, params: { uuid: article.uuid }, format: :turbo_stream

    assert article.reload.published?
  end
end
