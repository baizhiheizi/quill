# frozen_string_literal: true

require "test_helper"

class Mixpay::ClientTest < ActiveSupport::TestCase
  setup do
    # `HTTP.timeout` is how `Client#request` obtains its connection; swapping
    # it for a canned response lets these tests exercise the response-parsing
    # half of `request` without a live server.
    @original_http_timeout = HTTP.method(:timeout)
  end

  teardown do
    HTTP.singleton_class.send(:define_method, :timeout, @original_http_timeout)
  end

  test "HTTP client is available after requiring mixpay client" do
    assert HTTP.respond_to?(:timeout)
    assert defined?(HTTP::Error)
  end

  test "request raises HttpError when connection fails" do
    client = Mixpay::Client.new("127.0.0.1")

    error = assert_raises(Mixpay::Errors::HttpError) do
      client.get("/v1/setting/settlement_assets")
    end

    assert error.message.present?
  end

  test "request unwraps the data key from a successful envelope" do
    stub_http_response(body: '{"success":true,"data":{"assetId":"btc"}}', content_type: "application/json")

    assert_equal({ "assetId" => "btc" }, Mixpay::Client.new("api.mixpay.me").get("/v1/setting/quote_assets"))
  end

  test "request raises APIError when the envelope reports failure" do
    stub_http_response(body: '{"success":false,"message":"boom"}', content_type: "application/json")

    error = assert_raises(Mixpay::Errors::APIError) do
      Mixpay::Client.new("api.mixpay.me").get("/v1/setting/quote_assets")
    end

    assert_match(/boom/, error.message)
  end

  test "request raises APIError, not JSON::ParserError, when the body is not JSON" do
    stub_http_response(body: "<html>502 Bad Gateway</html>", content_type: "text/html")

    error = assert_raises(Mixpay::Errors::APIError) do
      Mixpay::Client.new("api.mixpay.me").get("/v1/setting/quote_assets")
    end

    assert_match(/non-JSON response/, error.message)
  end

  test "request raises APIError when the envelope is a top-level JSON array" do
    stub_http_response(body: '[{"assetId":"btc"}]', content_type: "application/json")

    assert_raises(Mixpay::Errors::APIError) do
      Mixpay::Client.new("api.mixpay.me").get("/v1/setting/quote_assets")
    end
  end

  test "uri_for builds a plain host without a port" do
    client = Mixpay::Client.new("api.mixpay.me")

    assert_equal "https://api.mixpay.me/v1/x", client.send(:uri_for, "/v1/x").to_s
  end

  test "uri_for builds an ip address host without a port" do
    client = Mixpay::Client.new("127.0.0.1")

    assert_equal "https://127.0.0.1/v1/x", client.send(:uri_for, "/v1/x").to_s
  end

  test "uri_for splits a port off a host that carries one" do
    client = Mixpay::Client.new("localhost:3000")

    assert_equal "https://localhost:3000/v1/x", client.send(:uri_for, "/v1/x").to_s
  end

  test "uri_for splits a port off a bracketed ipv6 host" do
    client = Mixpay::Client.new("[::1]:8080")

    assert_equal "https://[::1]:8080/v1/x", client.send(:uri_for, "/v1/x").to_s
  end

  test "uri_for keeps a bracketed ipv6 host that carries no port" do
    client = Mixpay::Client.new("[::1]")

    assert_equal "https://[::1]/v1/x", client.send(:uri_for, "/v1/x").to_s
  end

  test "request reaches a host that carries a port" do
    requested_uris = stub_http_response(body: '{"success":true,"data":{"assetId":"btc"}}', content_type: "application/json")

    assert_equal({ "assetId" => "btc" }, Mixpay::Client.new("localhost:3000").get("/v1/x"))
    assert_equal [ "https://localhost:3000/v1/x" ], requested_uris
  end

  test "request raises a Mixpay error, not an Addressable error, for a malformed host" do
    client = Mixpay::Client.new("bad host")

    error = assert_raises(Mixpay::Errors::Error) do
      client.get("/v1/x")
    end

    # A bare `Addressable::URI::InvalidURIError` is not a `Mixpay::Errors::Error`,
    # so the assertion above already fails if one escapes; assert it explicitly.
    refute_kind_of Addressable::URI::InvalidURIError, error
  end

  private

  # Records the URI each stubbed request was made with, so tests can assert
  # on the URL the client actually built.
  def stub_http_response(body:, content_type:)
    response = Class.new do
      def initialize(body:, content_type:)
        @body = body
        @content_type = content_type
      end

      def body = @body
      def headers = { content_type: @content_type }
      def to_s = "response"

      def status
        Struct.new(:server_error?).new(false)
      end
    end.new(body:, content_type:)

    requested_uris = []

    fake_client = Class.new do
      define_method(:get) { |uri, **_options| requested_uris << uri.to_s; response }
      define_method(:post) { |uri, **_options| requested_uris << uri.to_s; response }
    end

    HTTP.singleton_class.send(:define_method, :timeout) { |*_| fake_client.new }

    requested_uris
  end
end
