# frozen_string_literal: true

module ArweaveBot
  class Client
    SERVER_SCHEME = 'https'

    attr_reader :host

    def initialize(host = 'arweave.net')
      @host = host
    end

    def get(path, options = {})
      request(:get, uri_for(path), options)
    end

    def post(path, options = {})
      request(:post, uri_for(path), options)
    end

    private

    def request(verb, uri, options = {})
      options[:headers] ||= {}
      options[:headers]['Content-Type'] ||= 'application/json'

      begin
        response = HTTP.timeout(connect: 5, write: 5, read: 5).request(verb, uri, options)
      rescue HTTP::Error => e
        raise HttpError, e.message
      end

      raise ResponseError, response.to_s if response.status.server_error?

      if response.status.success?
        JSON.parse(response.body.to_s)
      elsif response.status.redirect?
        request :get, response.headers['Location']
      else
        response.status.to_s
      end
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
