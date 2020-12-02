# frozen_string_literal: true

module Foxswap
  class API
    attr_reader :client

    def initialize
      @client = Client.new
    end

    def pre_order(params)
      path = '/api/orders/pre'

      payload = {
        pay_asset_id: params[:pay_asset_id],
        fill_asset_id: params[:fill_asset_id],
        funds: params[:funds]&.to_s,
        amount: params[:amount]&.round(8)&.to_s
      }

      client.post path, json: payload, headers: { 'Authorization': Rails.application.credentials.dig(:foxswap, :authorization) }
    end

    def order(order_id, authorization:)
      path = "/api/orders/#{order_id}"
      client.get path, headers: { 'Authorization': authorization }
    end
  end
end
