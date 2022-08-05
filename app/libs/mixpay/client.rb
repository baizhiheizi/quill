# frozen_string_literal: true

module Mixpay
  class Client
    SERVER_SCHEME = 'https'

    attr_reader :host

    def initialize(host = 'api.mixpay.me')
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
        raise Errors::HttpError, e.message
      end

      raise Errors::APIError, response.to_s if response.status.server_error?

      parse_response(response) do |parse_as, result|
        case parse_as
        when :json
          break result[:data] if result[:success]

          raise Errors::APIError, result
        else
          result
        end
      end
    end

    def uri_for(path)
      uri_options = {
        scheme: SERVER_SCHEME,
        host: host,
        path: path
      }
      Addressable::URI.new(uri_options)
    end

    def parse_response(response)
      content_type = response.headers[:content_type]
      parse_as = {
        %r{^application/json} => :json,
        %r{^text/html} => :xml,
        %r{^text/plain} => :plain
      }.each_with_object([]) { |match, memo| memo << match[1] if content_type =~ match[0] }.first || :plain

      if parse_as == :plain
        result = JSON.parse(response&.body&.to_s)
        result && yield(:json, result)

        yield(:plain, response.body)
      end

      result = case parse_as
               when :json
                 JSON.parse(response.body.to_s).with_indifferent_access
               when :xml
                 Hash.from_xml(response.body.to_s)
               else
                 response.body
               end

      yield(parse_as, result)
    end
  end
end
