# frozen_string_literal: true

require "test_helper"

# Pins the contract of `API::RenderingHelper`, the small set of JSON render
# helpers mixed into `API::BaseController`. Every JSON-only controller in the
# API namespace (`api/articles_controller`, `api/home_controller`,
# `api/valid_users_controller`) plus the `rescue_from` blocks in
# `API::BaseController` itself reaches for these — the contract is therefore
# load-bearing for every JSON response shape the API returns.
#
# The host controller below is the smallest object that satisfies the
# concern: a single `#dispatch` action picks one of the render helpers based
# on the `kind` query param and forwards any optional `message` / `data`
# params. Each test invokes `dispatch` directly on a fresh controller
# instance — no routing (the host class is intentionally not in
# `config/routes.rb`) — and asserts on status, body, and (for the
# data-bearing helper) payload contents.
#
# `ActionDispatch::Assertions` gives us `assert_response` without dragging in
# `ActionController::TestCase` (whose `process` would try to URL-generate
# against `Rails.application.routes` for an unrouted controller).
class API::RenderingHelperTest < ActiveSupport::TestCase
  include ActionDispatch::Assertions

  HOST_CLASS = Class.new(ActionController::Base) do
    include API::RenderingHelper

    # Single dispatch action — the `kind` param selects which render helper
    # is invoked, the optional `message` / `data` params are forwarded as-is
    # to exercise the default-vs-custom-message branches.
    def dispatch
      case params[:kind]
      when "created_with_data"
        render_created(JSON.parse(params[:data]))
      when "created_default"
        render_created
      when "no_content"
        render_no_content
      when "unauthorized_default"
        render_unauthorized
      when "unauthorized_with_message"
        render_unauthorized(params[:message])
      when "forbidden_default"
        render_forbidden
      when "forbidden_with_message"
        render_forbidden(params[:message])
      when "not_found_default"
        render_not_found
      when "not_found_with_message"
        render_not_found(params[:message])
      when "unprocessable_entity_default"
        render_unprocessable_entity
      when "unprocessable_entity_with_message"
        render_unprocessable_entity(params[:message])
      when "internal_server_error_default"
        render_internal_server_error
      when "internal_server_error_with_message"
        render_internal_server_error(params[:message])
      else
        head :ok
      end
    end
  end

  setup do
    @controller = HOST_CLASS.new
    @request = ActionDispatch::TestRequest.create
    @response = ActionDispatch::TestResponse.new
    @controller.set_request!(@request)
    @controller.set_response!(@response)
  end

  def invoke(params = {})
    @controller.params = ActionController::Parameters.new(params)
    @controller.dispatch
  end

  # ---- render_created ---------------------------------------------------

  test "render_created returns :created with an empty JSON object when no data is given" do
    invoke(kind: "created_default")

    assert_response :created
    assert_equal "{}", @response.body
  end

  test "render_created serialises the supplied data as JSON under :created" do
    invoke(kind: "created_with_data", data: { foo: "bar", count: 2 }.to_json)

    assert_response :created
    assert_equal({ "foo" => "bar", "count" => 2 }.to_json, @response.body)
  end

  # ---- render_no_content ------------------------------------------------

  test "render_no_content returns :no_content with an empty body" do
    invoke(kind: "no_content")

    assert_response :no_content
    assert_equal "", @response.body
  end

  # ---- render_unauthorized ----------------------------------------------

  test "render_unauthorized returns :unauthorized with the default message" do
    invoke(kind: "unauthorized_default")

    assert_response :unauthorized
    assert_equal({ message: "Unauthorized" }.to_json, @response.body)
  end

  test "render_unauthorized returns the supplied message when one is given" do
    invoke(kind: "unauthorized_with_message", message: "Token expired")

    assert_response :unauthorized
    assert_equal({ message: "Token expired" }.to_json, @response.body)
  end

  # ---- render_forbidden -------------------------------------------------

  test "render_forbidden returns :forbidden with the default message" do
    invoke(kind: "forbidden_default")

    assert_response :forbidden
    assert_equal({ message: "Forbidden" }.to_json, @response.body)
  end

  test "render_forbidden returns the supplied message when one is given" do
    invoke(kind: "forbidden_with_message", message: "Blocked by author")

    assert_response :forbidden
    assert_equal({ message: "Blocked by author" }.to_json, @response.body)
  end

  # ---- render_not_found -------------------------------------------------

  test "render_not_found returns :not_found with the default message" do
    invoke(kind: "not_found_default")

    assert_response :not_found
    assert_equal({ message: "Not found" }.to_json, @response.body)
  end

  test "render_not_found returns the supplied message when one is given" do
    invoke(kind: "not_found_with_message", message: "Article not visible")

    assert_response :not_found
    assert_equal({ message: "Article not visible" }.to_json, @response.body)
  end

  # ---- render_unprocessable_entity --------------------------------------

  test "render_unprocessable_entity returns :unprocessable_entity with the default message" do
    invoke(kind: "unprocessable_entity_default")

    assert_response :unprocessable_entity
    assert_equal({ message: "Unprocessable entity" }.to_json, @response.body)
  end

  test "render_unprocessable_entity returns the supplied message when one is given" do
    invoke(kind: "unprocessable_entity_with_message", message: "Amount must be positive")

    assert_response :unprocessable_entity
    assert_equal({ message: "Amount must be positive" }.to_json, @response.body)
  end

  # ---- render_internal_server_error -------------------------------------

  test "render_internal_server_error returns :internal_server_error with the default message" do
    invoke(kind: "internal_server_error_default")

    assert_response :internal_server_error
    assert_equal({ message: "Internal server error" }.to_json, @response.body)
  end

  test "render_internal_server_error returns the supplied message when one is given" do
    invoke(kind: "internal_server_error_with_message", message: "Upstream timeout")

    assert_response :internal_server_error
    assert_equal({ message: "Upstream timeout" }.to_json, @response.body)
  end
end
