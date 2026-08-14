# frozen_string_literal: true

require "test_helper"

# `Dashboard::SubscriptionsController#index` is a thin shell that only sets
# `@tab` (defaults to `"subscribing_users"`) and lets the view lazily load
# the three subscription sub-frames via turbo frames (`subscribe_users`,
# `subscribe_articles`, `subscribe_tags`). The controller action has no
# queries of its own.
class Dashboard::SubscriptionsControllerTest < ActionController::TestCase
  tests Dashboard::SubscriptionsController

  setup do
    @reader = users(:reader_one)
    sign_in_as(@reader)
  end

  test "index renders the subscriptions shell" do
    get :index

    assert_response :success
    assert_template :index
  end

  test "index defaults @tab to subscribing_users when no param is given" do
    get :index

    assert_response :success
    assert_equal "subscribing_users", @controller.instance_variable_get(:@tab)
  end

  test "index honors the tab param when provided" do
    get :index, params: { tab: "commenting_subscribe_articles" }

    assert_response :success
    assert_equal "commenting_subscribe_articles", @controller.instance_variable_get(:@tab)
  end

  test "index forwards arbitrary tab strings through unchanged" do
    # The controller does not validate `tab`; the view chooses what to
    # render based on the value. A non-standard value is still echoed.
    get :index, params: { tab: "future_tab_name" }

    assert_response :success
    assert_equal "future_tab_name", @controller.instance_variable_get(:@tab)
  end

  test "index redirects to login for unauthenticated access" do
    @request.session[:current_session_id] = nil

    get :index

    assert_response :redirect
  end

  private

  def sign_in_as(user)
    test_session = sign_in(user)
    @request.session[:current_session_id] = test_session.uuid
  end
end
