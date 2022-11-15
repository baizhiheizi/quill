# frozen_string_literal: true

module ArweaveBot
  class API
    attr_reader :client

    def initialize
      @client = Client.new
    end

    def transaction(id)
      client.post id
    end
  end
end
