# frozen_string_literal: true

require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "GET /fair renders the stats page under the public layout" do
    get fair_page_path

    assert_response :success
    assert_select "h1", "Stats"
    assert_match(%r{assets/reader[^"]*\.js}, response.body)
  end

  test "GET /rules renders the rules page under the public layout" do
    get rules_page_path

    assert_response :success
    assert_select "h1", "Rules"
    assert_match(%r{assets/reader[^"]*\.js}, response.body)
  end
end
