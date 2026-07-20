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
    assert_not_nil @controller.instance_variable_get(:@sessions)
    assert_not_nil @controller.instance_variable_get(:@pagy)
    assert_equal "created_at_desc", @controller.instance_variable_get(:@order_by)
  end

  test "GET index assigns every session fixture" do
    get :index

    assert_response :success
    assigned = @controller.instance_variable_get(:@sessions).to_a
    assert_includes assigned, @author_session
    assert_includes assigned, @reader_session
  end

  test "GET index filters by user_id when provided" do
    get :index, params: { user_id: @reader_one.id }

    assert_response :success
    assigned = @controller.instance_variable_get(:@sessions).to_a
    assert_includes assigned, @reader_session
    refute_includes assigned, @author_session
  end

  test "GET index ignores blank user_id" do
    get :index, params: { user_id: "" }

    assert_response :success
    assigned = @controller.instance_variable_get(:@sessions).to_a
    assert_includes assigned, @author_session
    assert_includes assigned, @reader_session
  end

  test "GET index with order_by=created_at_desc returns descending order" do
    get :index, params: { order_by: "created_at_desc" }

    assert_response :success
    assert_equal "created_at_desc", @controller.instance_variable_get(:@order_by)
    ordered = @controller.instance_variable_get(:@sessions).to_a
    # The reader_session fixture has `created_at: 1.day.ago`; build a third
    # session that's strictly newer so we can assert ordering direction.
    newer = Session.create!(user: @reader_one, info: { "provider" => "mixin" })
    get :index, params: { order_by: "created_at_desc" }
    ordered = @controller.instance_variable_get(:@sessions).to_a
    assert_equal newer, ordered.first,
                 "expected the newest session first under created_at_desc"
    assert_equal @author_session, ordered.last,
                 "expected the oldest fixture last under created_at_desc"
  end

  test "GET index with order_by=created_at_asc returns ascending order" do
    get :index, params: { order_by: "created_at_asc" }

    assert_response :success
    assert_equal "created_at_asc", @controller.instance_variable_get(:@order_by)
    ordered = @controller.instance_variable_get(:@sessions).to_a
    # The two fixture sessions share `created_at: 1.day.ago`, so build a
    # third session that's strictly newer to make the ordering direction
    # unambiguous.
    newer = Session.create!(user: @reader_one, info: { "provider" => "mixin" })
    get :index, params: { order_by: "created_at_asc" }
    ordered = @controller.instance_variable_get(:@sessions).to_a
    # The newer session is the only row with a strict `created_at` of
    # `Time.current`; under ASC ordering it must be last. Asserting on
    # `ordered.first` would be non-deterministic because the two
    # `1.day.ago` fixture sessions tie on `created_at` and PG does not
    # guarantee a tiebreaker.
    assert_equal newer, ordered.last,
                 "expected the newest session last under created_at_asc"
    refute_equal newer, ordered.first,
                 "expected the newest session not first under created_at_asc"
  end

  test "GET index with unknown order_by falls back to created_at_desc" do
    get :index, params: { order_by: "garbage" }

    assert_response :success
    assert_equal "garbage", @controller.instance_variable_get(:@order_by)
    newer = Session.create!(user: @reader_one, info: { "provider" => "mixin" })
    get :index, params: { order_by: "garbage" }
    ordered = @controller.instance_variable_get(:@sessions).to_a
    assert_equal newer, ordered.first,
                 "expected fallback to created_at_desc when order_by is unknown"
  end

  test "GET index filters and orders together" do
    get :index, params: { user_id: @reader_one.id, order_by: "created_at_asc" }

    assert_response :success
    assigned = @controller.instance_variable_get(:@sessions).to_a
    assert_includes assigned, @reader_session
    refute_includes assigned, @author_session
  end

  test "GET index redirects to login when unauthenticated" do
    @request.session[:current_admin_id] = nil

    get :index

    assert_redirected_to admin_login_path
  end
end
