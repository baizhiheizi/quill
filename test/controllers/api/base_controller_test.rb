# frozen_string_literal: true

require "test_helper"

# Pins API::BaseController's request contract: token authentication (401),
# the rescue_from matrix's response shapes (403/404/422/500), and the
# last_request audit written by store_access_token_request. The plain paths
# go through the real /api routes; the error families no live endpoint can
# reach go through a test-only probe controller mounted with with_routing.
class API::BaseControllerTest < IntegrationTestCase
  test "create without a token renders 401" do
    post api_articles_path, params: { article: { title: "x" } }, as: :json

    assert_response :unauthorized
    assert_equal "Unauthorized", response.parsed_body["message"]
  end

  test "create with an unknown token value renders 401" do
    post api_articles_path,
      headers: { "HTTP_X_ACCESS_TOKEN" => "00000000-0000-4000-8000-000000000000" },
      params: { article: { title: "x" } }, as: :json

    assert_response :unauthorized
  end

  test "a soft-deleted token no longer authenticates" do
    access_tokens(:reader_token).update!(deleted_at: Time.current)

    post api_articles_path, headers: api_headers(access_tokens(:reader_token)),
      params: { article: { title: "x" } }, as: :json

    assert_response :unauthorized
  end

  test "an unknown article uuid renders the RecordNotFound 404" do
    get api_article_path("no-such-uuid"), as: :json

    assert_response :not_found
    assert_equal "Not found", response.parsed_body["message"]
  end

  test "a failed create renders the validation messages as 422" do
    post api_articles_path, headers: api_headers(access_tokens(:author_token)),
      params: { article: { title: "x" * 65, intro: "y" } }, as: :json

    assert_response :unprocessable_entity
    assert_includes response.parsed_body["message"], "Title is too long (maximum is 64 characters)"
  end

  test "an authenticated request stores the token's last_request audit" do
    get api_articles_path, headers: api_headers(access_tokens(:reader_token)), as: :json

    assert_response :success
    audit = access_tokens(:reader_token).reload.last_request
    assert_equal "GET", audit["method"]
    assert_equal "127.0.0.1", audit["ip"]
    assert audit["url"].ends_with?("/api/articles")
    assert audit["at"].present?
  end

  test "guest requests store no last_request audit" do
    get api_articles_path, as: :json

    assert_response :success
    assert access_tokens(:reader_token).reload.last_request.blank?
  end

  test "the rescue matrix maps every error family to its response" do
    with_routing do |routes|
      routes.draw do
        namespace :api, defaults: { format: :json } do
          get "probe_pundit" => "probe#pundit_denied"
          get "probe_unprocessable" => "probe#explicit_unprocessable"
          get "probe_record_invalid" => "probe#record_invalid"
          get "probe_boom" => "probe#boom"
        end
      end

      get "/api/probe_pundit"
      assert_response :forbidden
      assert_equal "Forbidden", response.parsed_body["message"]

      get "/api/probe_unprocessable"
      assert_response :unprocessable_entity
      assert_equal "no dice", response.parsed_body["message"]

      get "/api/probe_record_invalid"
      assert_response :unprocessable_entity
      assert_match(/Validation failed/, response.parsed_body["message"])

      get "/api/probe_boom"
      assert_response :internal_server_error
      # Rails.env.local? is true in the test environment, so the base
      # controller discloses the raw message here; production gets the
      # masked "Internal server error".
      assert_equal "probe kaboom", response.parsed_body["message"]
    end
  end
end

class API::ProbeController < API::BaseController
  def pundit_denied
    raise Pundit::NotAuthorizedError
  end

  def explicit_unprocessable
    raise API::BaseController::UnprocessableEntityError, "no dice"
  end

  def record_invalid
    Article.new.save!
  end

  def boom
    raise "probe kaboom"
  end
end
