# frozen_string_literal: true

require "test_helper"

# `Dashboard::SubscribeUsersController#index` renders a paginated list of
# users the current user subscribes to, with avatar chain preloading and a
# preloaded set of subscribed user IDs to avoid N+1 checks in the partial.
class Dashboard::SubscribeUsersControllerTest < ActionController::TestCase
  tests Dashboard::SubscribeUsersController

  setup do
    @author = users(:author)
    session[:current_session_id] = Session.create!(
      user: @author,
      uuid: SecureRandom.uuid,
      info: { "provider" => "mixin" }
    ).uuid
  end

  test "index renders empty state when user subscribes to no one" do
    get :index

    assert_response :success
    users = @controller.instance_variable_get(:@users)
    assert users.blank?
  end

  test "index renders subscribed users list" do
    target = users(:reader_one)
    @author.create_action(:subscribe, target: target)

    get :index

    assert_response :success
    users = @controller.instance_variable_get(:@users)
    assert_includes users, target
  end

  test "index sets preloaded_subscribe_user_ids" do
    target = users(:reader_one)
    @author.create_action(:subscribe, target: target)

    get :index

    assert_response :success
    preloaded = @controller.instance_variable_get(:@preloaded_subscribe_user_ids)
    assert_not_nil preloaded
    assert_includes preloaded, target.id
  end

  test "index orders subscribed users by most recently subscribed first" do
    reader_one = users(:reader_one)
    reader_two = users(:reader_two)
    @author.create_action(:subscribe, target: reader_two)
    @author.create_action(:subscribe, target: reader_one)

    get :index

    assert_response :success
    users = @controller.instance_variable_get(:@users)
    assert_equal reader_one.id, users.first.id
  end

  test "index sets up pagination" do
    # Use the configured pagy items per page (default 25). Create enough
    # subscribed users to span 2 pages so `pagy.pages > 1`.
    items_per_page = Pagy::DEFAULT[:items] || 25
    (items_per_page + 1).times do |i|
      target = User.create!(
        uid: "60000#{i}",
        name: "Subscribed User #{i}",
        mixin_uuid: SecureRandom.uuid,
        mixin_id: "60000#{i}"
      )
      @author.create_action(:subscribe, target: target)
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
