# frozen_string_literal: true

require "test_helper"

# Regression for #2137: Admin::BaseController inherits ActionController::Base
# directly (not ApplicationController), so a before_action on ApplicationController
# never runs for the admin namespace. Admin index actions paginate via the same
# Pagy::Method, so `?page=0` must be coerced there too.
class Admin::PaginationCoercionTest < ActionController::TestCase
  tests Admin::UsersController

  setup do
    @request.session[:current_admin_id] = administrators(:one).id
  end

  test "admin index coerces ?page=0 instead of raising Pagy::OptionError" do
    get :index, params: { page: "0" }
    assert_response :success
  end

  test "admin index coerces out-of-range and unparseable ?page= values" do
    # A huge page number is as hostile as a sub-1 one: pagy turns it into
    # `limit * (page - 1)`, which overflows a Postgres bigint and used to
    # raise `PG::NumericValueOutOfRange` -> HTTP 500.
    %w[-1 abc 0foo 99999999999999999999].each do |bad|
      get :index, params: { page: bad }
      assert_response :success, "expected success for page=#{bad.inspect}"
    end
  end

  test "admin index keeps a legitimate deep page" do
    get :index, params: { page: "2" }

    assert_response :success
    assert_equal 2, effective_pagy_page,
      "expected page=2 to stay on page 2 instead of being clamped"
  end

  test "admin index clamps a page above the maximum to the first page" do
    get :index, params: { page: "99999999999999999999" }

    assert_response :success
    assert_equal 1, effective_pagy_page,
      "expected an out-of-range page to be clamped to page 1"
  end

  private

  def effective_pagy_page
    @controller.instance_variable_get(:@pagy)&.page
  end
end
