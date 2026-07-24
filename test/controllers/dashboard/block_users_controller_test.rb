# frozen_string_literal: true

require "test_helper"

# `Dashboard::BlockUsersController#index` renders a paginated list of users
# the current user has blocked, with avatar avatar chain preloading and a
# preloaded set of blocked user IDs to avoid N+1 checks in the partial.
class Dashboard::BlockUsersControllerTest < ActionController::TestCase
  tests Dashboard::BlockUsersController

  setup do
    @author = users(:author)
    session[:current_session_id] = Session.create!(
      user: @author,
      uuid: SecureRandom.uuid,
      info: { "provider" => "mixin" }
    ).uuid
  end

  test "index renders empty state when no users are blocked" do
    get :index

    assert_response :success
    users = @controller.instance_variable_get(:@users)
    assert users.blank?
  end

  test "index renders blocked users list" do
    reader = users(:reader_one)
    @author.block_user(reader)

    get :index

    assert_response :success
    users = @controller.instance_variable_get(:@users)
    assert_includes users, reader
  end

  test "index sets preloaded_block_user_ids" do
    reader = users(:reader_one)
    @author.block_user(reader)

    get :index

    assert_response :success
    preloaded = @controller.instance_variable_get(:@preloaded_block_user_ids)
    assert_not_nil preloaded
    assert_includes preloaded, reader.id
  end

  test "index orders blocked users by most recently blocked first" do
    reader_one = users(:reader_one)
    reader_two = users(:reader_two)
    @author.block_user(reader_two)
    @author.block_user(reader_one)

    get :index

    assert_response :success
    users = @controller.instance_variable_get(:@users)
    assert_equal reader_one.id, users.first.id
  end

  test "index sets up pagination" do
    # Use the configured pagy items per page (default 25). Create enough
    # blocked users to span 2 pages so `pagy.pages > 1`.
    items_per_page = Pagy::DEFAULT[:items] || 25
    (items_per_page + 1).times do |i|
      target = User.create!(
        uid: "50000#{i}",
        name: "Blocked User #{i}",
        mixin_uuid: SecureRandom.uuid,
        mixin_id: "50000#{i}"
      )
      @author.block_user(target)
    end

    get :index

    assert_response :success
    pagy = @controller.instance_variable_get(:@pagy)
    assert_not_nil pagy
    assert_equal 2, pagy.pages
  end

  test "index redirects to login for unauthenticated access" do
    session.delete(:current_session_id)

    get :index

    assert_response :redirect
  end
end
