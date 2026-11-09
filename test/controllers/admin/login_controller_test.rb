# frozen_string_literal: true

require "test_helper"

class Admin::LoginControllerTest < ActionController::TestCase
  tests Admin::LoginController

  test "GET new renders the login form without requiring authentication" do
    get :new

    assert_response :success
    assert_nil @request.session[:current_admin_id]
  end

  test "POST create signs in the admin with valid credentials" do
    admin = Administrator.create!(name: "login-test", password: "correct horse battery staple")

    post :create, params: { name: admin.name, password: "correct horse battery staple" }

    assert_redirected_to admin_root_path
    assert_equal admin.id, @request.session[:current_admin_id]
  end

  test "POST create rejects a wrong password without signing in" do
    admin = Administrator.create!(name: "wrong-password", password: "hunter2")

    post :create, params: { name: admin.name, password: "not-hunter2" }

    assert_redirected_to admin_root_path
    assert_nil @request.session[:current_admin_id]
  end

  test "POST create rejects an unknown name without signing in" do
    post :create, params: { name: "no-such-admin", password: "whatever" }

    assert_redirected_to admin_root_path
    assert_nil @request.session[:current_admin_id]
  end

  test "GET logout signs out and redirects to the admin root" do
    @request.session[:current_admin_id] = administrators(:one).id

    # The logout route (GET admin/logout) maps to the `delete` action.
    get :delete

    assert_redirected_to admin_root_path
    assert_nil @request.session[:current_admin_id]
  end
end
