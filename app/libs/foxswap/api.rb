# frozen_string_literal: true

module Foxswap
  class API
    attr_reader :client

    def initialize
      @client = Client.new
    end

    def pre_order(params)
      path = '/orders/pre'

      payload = {
        pay_asset_id: params[:pay_asset_id],
        fill_asset_id: params[:fill_asset_id],
        funds: params[:funds],
        amount: params[:amount]
      }

      client.post path, json: payload
    end

    def order(order_id, authorization:)
      path = "/orders/#{order_id}"
      client.get path, headers: { 'Authorization': authorization }
    end
  end
end
