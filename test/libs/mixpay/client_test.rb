# frozen_string_literal: true

require "test_helper"

class Mixpay::ClientTest < ActiveSupport::TestCase
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
end
