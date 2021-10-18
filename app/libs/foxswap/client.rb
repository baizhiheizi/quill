# frozen_string_literal: true

module Foxswap
  class Client
    SERVER_SCHEME = 'https'

    attr_reader :host

    def initialize(host = 'api.4swap.org')
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
      options[:headers]['Content-Type'] ||= 'application/json'

      begin
        response = HTTP.timeout(connect: 5, write: 5, read: 5).request(verb, uri, options)
      rescue HTTP::Error => e
        raise HttpError, e.message
      end

      raise ResponseError, response.to_s if response.status.server_error?
      return response.status.to_s unless response.status.success?

      JSON.parse(response.body.to_s)
    end

    def uri_for(path)
      uri_options = {
        scheme: SERVER_SCHEME,
        host: host,
        path: path
      }
      Addressable::URI.new(uri_options)
    end
  end
end
