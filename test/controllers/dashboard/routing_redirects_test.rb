# frozen_string_literal: true

require "test_helper"

# Every pre-redesign dashboard path enumerated in
# specs/005-dashboard-ux-redesign/data-model.md's Route Redirect Map must keep
# resolving (FR-030/SC-008) once routes are regrouped under the new
# Overview/Write/Read/Finances/Account sections.
class Dashboard::RoutingRedirectsTest < ActionController::TestCase
  tests Dashboard::HomeController

  setup do
    @user = users(:author)
    test_session = sign_in(@user)
    @request.session[:current_session_id] = test_session.uuid
    # `dashboard/settings/_notification` renders a `form_with` bound to
    # `current_user.notification_setting`, which is nil for fixtures with no
    # explicit setting — synthesise one, same as
    # `test/controllers/dashboard/notifications_controller_test.rb`.
    ensure_notification_setting!(@user) if @user.notification_setting.blank?
  end

  test "dashboard_root_path renders the Overview (never a dead end)" do
    get :index

    assert_response :success
  end

  test "old readings path redirects to the new read section, tab preserved" do
    get :redirect_readings, params: { tab: "subscriptions" }

    assert_redirected_to dashboard_read_path(tab: "subscriptions")
  end

  test "old readings path with no tab redirects cleanly" do
    get :redirect_readings

    assert_response :redirect
    assert_redirected_to dashboard_read_path(tab: nil)
  end

  test "old authorings path redirects to the new write section, tab preserved" do
    get :redirect_authorings, params: { tab: "collections" }

    assert_redirected_to dashboard_write_path(tab: "collections")
  end

  test "old settings path redirects to the new account section, tab preserved" do
    get :redirect_settings, params: { tab: "notification" }

    assert_redirected_to dashboard_account_path(tab: "notification")
  end

  test "old stats path redirects into the dashboard root (absorbed into Overview)" do
    get :redirect_stats

    assert_redirected_to dashboard_root_path
  end

  test "new canonical section landing routes all render successfully" do
    get :write
    assert_response :success

    get :read
    assert_response :success

    get :account
    assert_response :success
  end
end
