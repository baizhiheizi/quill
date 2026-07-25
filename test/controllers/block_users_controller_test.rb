# frozen_string_literal: true

require "test_helper"

class BlockUsersControllerTest < ActionController::TestCase
  tests BlockUsersController

  setup do
    @reader = users(:reader_one)
    @author = users(:author)
    session[:current_session_id] = Session.create!(
      user: @reader,
      uuid: SecureRandom.uuid,
      info: { "provider" => "mixin" }
    ).uuid
  end

  test "new renders successfully" do
    get :new, params: { uid: @author.uid }

    assert_response :success
  end

  test "create blocks the target user and removes mutual subscriptions" do
    @reader.create_action(:subscribe, target: @author)
    @author.create_action(:subscribe, target: @reader)

    post :create, params: { uid: @author.uid }, format: :turbo_stream

    assert_response :success
    assert @reader.reload.block_user?(@author)
    assert_not @reader.reload.subscribe_user?(@author)
    assert_not @author.reload.subscribe_user?(@reader)
  end

  test "create is a no-op when blocking self" do
    post :create, params: { uid: @reader.uid }, format: :turbo_stream

    assert_response :success
    assert_not @reader.reload.block_user?(@reader)
  end

  test "destroy unblocks the target user" do
    @reader.block_user(@author)
    assert @reader.reload.block_user?(@author)

    delete :destroy, params: { uid: @author.uid }, format: :turbo_stream

    assert_response :success
    assert_not @reader.reload.block_user?(@author)
  end

  test "destroy is a no-op when unblocking self" do
    delete :destroy, params: { uid: @reader.uid }, format: :turbo_stream

    assert_response :success
    assert_not @reader.reload.block_user?(@reader)
  end

  test "actions redirect to login for unauthenticated access" do
    session.delete(:current_session_id)

    post :create, params: { uid: @author.uid }

    assert_response :redirect
  end
end
