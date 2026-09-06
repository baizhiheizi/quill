# frozen_string_literal: true

require "http"

module Mixpay
  class Client
    SERVER_SCHEME = "https"

    attr_reader :host

    def initialize(host = "api.mixpay.me")
      @host = host
    end

    def get(path, options = {})
      request(:get, path, options)
    end

    def post(path, options = {})
      request(:post, path, options)
    end

    private

    def request(verb, path, options = {})
      uri = uri_for path

      options[:headers] ||= {}
      options[:headers]["Content-Type"] ||= "application/json"

      client = HTTP.timeout(connect: 5, write: 5, read: 5)
      request_options = options.slice(:params, :json, :body, :form).merge(headers: options[:headers])

      begin
        response = client.public_send(verb, uri.to_s, **request_options)
      rescue HTTP::Error, Errno::ECONNREFUSED, Errno::ETIMEDOUT, SocketError => e
        raise Errors::HttpError, e.message
      end

      raise Errors::APIError, response.to_s if response.status.server_error?

      # Mixpay answers JSON for every endpoint this client talks to; the
      # envelope is `{ success:, data: }`. A body that is not JSON (a proxy or
      # WAF error page, an empty body) still becomes an APIError: callers
      # rescue `Mixpay::Errors::Error` to degrade gracefully, so letting a
      # bare JSON::ParserError escape would turn a Mixpay outage into a 500.
      result =
        begin
          JSON.parse(response.body.to_s)
        rescue JSON::ParserError
          raise Errors::APIError, "non-JSON response: #{response.body.to_s[0, 200]}"
        end

      raise Errors::APIError, result unless result.is_a?(Hash) && result["success"]

      result["data"]
    end

    def uri_for(path)
      uri_options = {
        scheme: SERVER_SCHEME,
        host:,
        path:
      }
      Addressable::URI.new(uri_options)
    end
  end
end
