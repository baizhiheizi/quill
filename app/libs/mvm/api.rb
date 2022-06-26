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

    def extra(receivers: [], threshold: 1, extra: '')
      return if receivers.blank?

      path = '/extra'

      payload = {
        receivers: receivers,
        threshold: threshold,
        extra: extra
      }

      client.post path, json: payload
    end
  end
end
