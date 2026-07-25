# frozen_string_literal: true

require "test_helper"

class TagsControllerTest < ActionController::TestCase
  tests TagsController

  setup do
    @web3 = tags(:web3)
    @tech_zh = tags(:tech_zh)
  end

  test "index responds to JSON by returning tag names" do
    get :index, format: :json

    assert_response :success
    body = JSON.parse(@response.body)
    assert_includes body, @web3.name
  end

  test "index filters by name when query is provided (JSON branch)" do
    get :index, params: { query: "web" }, format: :json

    assert_response :success
    body = JSON.parse(@response.body)
    assert_includes body, @web3.name
    assert_not_includes body, @tech_zh.name
  end
end
