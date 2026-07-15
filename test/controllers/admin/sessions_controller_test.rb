# frozen_string_literal: true

require "test_helper"

class Admin::SessionsControllerTest < ActionController::TestCase
  tests Admin::SessionsController

  setup do
    @admin = administrators(:one)
    # `Admin::BaseController#authenticate_admin!` only checks
    # `current_admin.blank?`. We bypass it by setting the session directly.
    @request.session[:current_admin_id] = @admin.id

    @author = users(:author)
    @reader_one = users(:reader_one)
    @author_session = sessions(:author_session)
    @reader_session = sessions(:reader_session)
  end

  test "GET index renders successfully" do
    get :index

    assert_response :success
    assert_not_nil assigns(:sessions)
    assert_not_nil assigns(:pagy)
    assert_equal "created_at_desc", assigns(:order_by)
  end

  test "GET index assigns every session fixture" do
    get :index

    assert_response :success
    assigned = assigns(:sessions).to_a
    assert_includes assigned, @author_session
    assert_includes assigned, @reader_session
  end

  test "GET index filters by user_id when provided" do
    get :index, params: { user_id: @reader_one.id }

    assert_response :success
    assigned = assigns(:sessions).to_a
    assert_includes assigned, @reader_session
    refute_includes assigned, @author_session
  end

  test "GET index ignores blank user_id" do
    get :index, params: { user_id: "" }

    assert_response :success
    assigned = assigns(:sessions).to_a
    assert_includes assigned, @author_session
    assert_includes assigned, @reader_session
  end

  test "GET index with order_by=created_at_desc returns descending order" do
    get :index, params: { order_by: "created_at_desc" }

    assert_response :success
    assert_equal "created_at_desc", assigns(:order_by)
    ordered = assigns(:sessions).to_a
    # The reader_session fixture has `created_at: 1.day.ago`; build a third
    # session that's strictly newer so we can assert ordering direction.
    newer = Session.create!(user: @reader_one, info: { "provider" => "mixin" })
    get :index, params: { order_by: "created_at_desc" }
    ordered = assigns(:sessions).to_a
    assert_equal newer, ordered.first,
                 "expected the newest session first under created_at_desc"
    assert_equal @author_session, ordered.last,
                 "expected the oldest fixture last under created_at_desc"
  end

  test "GET index with order_by=created_at_asc returns ascending order" do
    get :index, params: { order_by: "created_at_asc" }

    assert_response :success
    assert_equal "created_at_asc", assigns(:order_by)
    ordered = assigns(:sessions).to_a
    # The two fixture sessions share `created_at: 1.day.ago`, so build a
    # third session that's strictly newer to make the ordering direction
    # unambiguous.
    newer = Session.create!(user: @reader_one, info: { "provider" => "mixin" })
    get :index, params: { order_by: "created_at_asc" }
    ordered = assigns(:sessions).to_a
    assert_equal @author_session, ordered.first,
                 "expected the oldest fixture first under created_at_asc"
    assert_equal newer, ordered.last,
                 "expected the newest session last under created_at_asc"
  end

  test "GET index with unknown order_by falls back to created_at_desc" do
    get :index, params: { order_by: "garbage" }

    assert_response :success
    assert_equal "garbage", assigns(:order_by)
    newer = Session.create!(user: @reader_one, info: { "provider" => "mixin" })
    get :index, params: { order_by: "garbage" }
    ordered = assigns(:sessions).to_a
    assert_equal newer, ordered.first,
                 "expected fallback to created_at_desc when order_by is unknown"
  end

  test "GET index filters and orders together" do
    get :index, params: { user_id: @reader_one.id, order_by: "created_at_asc" }

    assert_response :success
    assigned = assigns(:sessions).to_a
    assert_includes assigned, @reader_session
    refute_includes assigned, @author_session
  end

  test "GET index redirects to login when unauthenticated" do
    @request.session[:current_admin_id] = nil

    get :index

    assert_redirected_to admin_login_path
  end
end
