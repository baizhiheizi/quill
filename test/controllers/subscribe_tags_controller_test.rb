# frozen_string_literal: true

require "test_helper"

class SubscribeTagsControllerTest < ActionController::TestCase
  tests SubscribeTagsController

  setup do
    @reader = users(:reader_one)
    @tag = tags(:web3)
    session[:current_session_id] = Session.create!(
      user: @reader,
      uuid: SecureRandom.uuid,
      info: { "provider" => "mixin" }
    ).uuid
  end

  test "new renders successfully" do
    get :new, params: { id: @tag.id }

    assert_response :success
  end

  test "create subscribes the current user to the target tag" do
    post :create, params: { id: @tag.id }, format: :turbo_stream

    assert_response :success
    assert @reader.reload.subscribe_tag?(@tag)
  end

  test "destroy unsubscribes the current user from the target tag" do
    @reader.create_action(:subscribe, target: @tag)
    assert @reader.reload.subscribe_tag?(@tag)

    delete :destroy, params: { id: @tag.id }, format: :turbo_stream

    assert_response :success
    assert_not @reader.reload.subscribe_tag?(@tag)
  end

  test "actions redirect to login for unauthenticated access" do
    session.delete(:current_session_id)

    post :create, params: { id: @tag.id }

    assert_response :redirect
  end
end
