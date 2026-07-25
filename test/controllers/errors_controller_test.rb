# frozen_string_literal: true

require "test_helper"

class ErrorsControllerTest < ActionController::TestCase
  tests ErrorsController

  test "not_found renders 404" do
    get :not_found

    assert_response :not_found
    assert_equal "404", @controller.instance_variable_get(:@page_title)
  end

  test "internal_server_error renders 500" do
    get :internal_server_error

    assert_response :internal_server_error
    assert_equal "500", @controller.instance_variable_get(:@page_title)
  end

  test "unprocessable_entity renders 422" do
    get :unprocessable_entity

    assert_response :unprocessable_entity
    assert_equal "422", @controller.instance_variable_get(:@page_title)
  end

  test "not_acceptable renders 406" do
    get :not_acceptable

    assert_response :not_acceptable
    assert_equal "406", @controller.instance_variable_get(:@page_title)
  end
end
