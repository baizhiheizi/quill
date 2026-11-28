# frozen_string_literal: true

require "http"

module Mixpay
  class Client
    SERVER_SCHEME = "https"

    # A host may carry its port ("localhost:3000", "[::1]:8080"). Addressable
    # 2.10 rejects a colon inside a host, so the port is split off before the
    # URI is built: a bracketed IPv6 literal keeps its brackets, a plain host
    # keeps its name.
    HOST_WITH_PORT = /\A(?<host>\[[^\]]+\]|[^:]+)(?::(?<port>\d+))?\z/

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
        path:
      }.merge(host_and_port)

      Addressable::URI.new(uri_options)
    rescue Addressable::URI::InvalidURIError => e
      # A malformed host must not escape as a bare Addressable exception:
      # callers rescue `Mixpay::Errors::Error` to degrade gracefully, so a
      # bad host has to surface as one of our own errors.
      raise Errors::HttpError, "invalid Mixpay host: #{e.message}"
    end

    # Addressable 2.10 (GHSA-w5p3-7836-69vh) rejects a colon in a host, so a
    # host carrying a port is split into its host and port parts first. An
    # IPv6 literal keeps its brackets: "[::1]:8080" becomes host "[::1]" and
    # port 8080.
    def host_and_port
      match = HOST_WITH_PORT.match(host.to_s)
      return { host: } unless match

      parts = { host: match[:host] }
      parts[:port] = match[:port].to_i if match[:port]
      parts
    end
  end
end
