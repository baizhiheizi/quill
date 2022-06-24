# frozen_string_literal: true

module MVM
  class API
    attr_reader :client

    def initialize
      @client = Client.new
    end

    def user(public_key)
      path = '/users'

      payload = {
        public_key: public_key
      }

      client.post path, json: payload
    end
  end
end
