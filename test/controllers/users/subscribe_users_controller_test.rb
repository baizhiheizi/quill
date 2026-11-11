# frozen_string_literal: true

require "test_helper"

# Controller-level coverage for the public "subscribings" modal on a user's
# profile (`/users/:user_uid/subscribe_users`). The listed user comes from
# the route, not the session — the page is reachable without authentication.
class Users::SubscribeUsersControllerTest < ActionController::TestCase
  tests Users::SubscribeUsersController

  setup do
    @author = users(:author)
  end

  test "index returns not found for an unknown user uid" do
    get :index, params: { user_uid: "no-such-uid" }

    assert_response :not_found
  end

  test "index lists the users the selected user subscribes to" do
    target = users(:reader_one)
    @author.create_action(:subscribe, target: target)

    get :index, params: { user_uid: @author.uid }

    assert_response :success
    users = @controller.instance_variable_get(:@users)
    assert_includes users, target
  end

  test "index does not list users subscribing to the selected user" do
    subscriber = users(:reader_one)
    subscriber.create_action(:subscribe, target: @author)

    get :index, params: { user_uid: @author.uid }

    assert_response :success
    users = @controller.instance_variable_get(:@users)
    assert_not_includes users, subscriber
  end

  test "index orders subscriptions by most recently subscribed first" do
    reader_one = users(:reader_one)
    reader_two = users(:reader_two)
    @author.create_action(:subscribe, target: reader_two)
    @author.create_action(:subscribe, target: reader_one)

    get :index, params: { user_uid: @author.uid }

    assert_response :success
    users = @controller.instance_variable_get(:@users)
    assert_equal reader_one.id, users.first.id
  end

  # `ViewerActionSets#ids_for` is viewer-relative: guests get an empty Set
  # (no query) and the partial falls through to the per-row check.
  test "index gives guests an empty preloaded set" do
    target = users(:reader_one)
    @author.create_action(:subscribe, target: target)

    get :index, params: { user_uid: @author.uid }

    assert_response :success
    assert_equal Set.new, @controller.instance_variable_get(:@preloaded_subscribe_user_ids)
  end

  test "index preloads the viewer's subscribed user ids" do
    viewer = users(:reader_one)
    target = users(:reader_two)
    viewer.create_action(:subscribe, target: target)
    session[:current_session_id] = sign_in(viewer).uuid

    get :index, params: { user_uid: @author.uid }

    assert_response :success
    preloaded = @controller.instance_variable_get(:@preloaded_subscribe_user_ids)
    assert_includes preloaded, target.id
  end

  test "index sets up pagination" do
    items_per_page = Pagy::DEFAULT[:items] || 25
    (items_per_page + 1).times do |i|
      target = User.create!(
        uid: "90000#{i}",
        name: "Subscribed User #{i}",
        mixin_uuid: SecureRandom.uuid,
        mixin_id: "90000#{i}"
      )
      @author.create_action(:subscribe, target: target)
    end

    get :index, params: { user_uid: @author.uid }

    assert_response :success
    pagy = @controller.instance_variable_get(:@pagy)
    assert_not_nil pagy
    assert_equal 2, pagy.pages
  end

  test "index sets the selected user's profile page meta" do
    get :index, params: { user_uid: @author.uid }

    assert_response :success
    assert_equal @author.name, @controller.instance_variable_get(:@page_title)
  end
end
