# frozen_string_literal: true

require "test_helper"

class SubscribeArticlesControllerTest < ActionController::TestCase
  tests SubscribeArticlesController

  setup do
    @reader = users(:reader_one)
    @article = articles(:published_free)
    session[:current_session_id] = Session.create!(
      user: @reader,
      uuid: SecureRandom.uuid,
      info: { "provider" => "mixin" }
    ).uuid
  end

  test "new renders successfully" do
    get :new, params: { uuid: @article.uuid }

    assert_response :success
  end

  test "create subscribes the current user to commenting on the article" do
    post :create, params: { uuid: @article.uuid }, format: :turbo_stream

    assert_response :success
    assert @reader.reload.commenting_subscribe_article?(@article)
  end

  test "destroy unsubscribes the current user from commenting on the article" do
    @reader.create_action(:commenting_subscribe, target: @article)
    assert @reader.reload.commenting_subscribe_article?(@article)

    delete :destroy, params: { uuid: @article.uuid }, format: :turbo_stream

    assert_response :success
    assert_not @reader.reload.commenting_subscribe_article?(@article)
  end

  test "actions redirect to login for unauthenticated access" do
    session.delete(:current_session_id)

    post :create, params: { uuid: @article.uuid }

    assert_response :redirect
  end
end
