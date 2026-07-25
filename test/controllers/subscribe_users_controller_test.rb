# frozen_string_literal: true

require "test_helper"

class SubscribeUsersControllerTest < ActionController::TestCase
  tests SubscribeUsersController

  setup do
    @reader = users(:reader_one)
    @author = users(:author)
    session[:current_session_id] = Session.create!(
      user: @reader,
      uuid: SecureRandom.uuid,
      info: { "provider" => "mixin" }
    ).uuid
  end

  test "create subscribes the current user to the target user" do
    post :create, params: { uid: @author.uid }, format: :turbo_stream

    assert_response :success
    assert @reader.reload.subscribe_user?(@author)
  end

  test "create is a no-op when subscribing to self" do
    post :create, params: { uid: @reader.uid }, format: :turbo_stream

    assert_response :success
    assert_not Action.exists?(user: @reader, target: @reader, action_type: "subscribe")
  end

  test "create is a no-op when the target has blocked the current user" do
    @author.block_user(@reader)

    post :create, params: { uid: @author.uid }, format: :turbo_stream

    assert_response :success
    assert_not @reader.reload.subscribe_user?(@author)
  end

  test "destroy unsubscribes the current user from the target user" do
    @reader.create_action(:subscribe, target: @author)
    assert @reader.reload.subscribe_user?(@author)

    delete :destroy, params: { uid: @author.uid }, format: :turbo_stream

    assert_response :success
    assert_not @reader.reload.subscribe_user?(@author)
  end

  test "destroy is a no-op when unsubscribing from self" do
    @reader.create_action(:subscribe, target: @author)
    delete :destroy, params: { uid: @reader.uid }, format: :turbo_stream

    assert_response :success
    assert @reader.reload.subscribe_user?(@author)
  end

  test "actions redirect to login for unauthenticated access" do
    session.delete(:current_session_id)

    post :create, params: { uid: @author.uid }

    assert_response :redirect
  end
end
