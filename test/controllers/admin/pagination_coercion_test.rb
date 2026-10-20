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
    %w[-1 abc 0foo].each do |bad|
      get :index, params: { page: bad }
      assert_response :success, "expected success for page=#{bad.inspect}"
    end
  end
end
