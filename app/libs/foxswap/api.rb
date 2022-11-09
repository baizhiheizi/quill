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

      client.post path, json: payload, headers: { Authorization: Rails.application.credentials.dig(:foxswap, :authorization) }
    end

    def pairs
      path = '/api/pairs'
      client.get path
    end

    def swappable_asset_ids
      Rails.cache.fetch('swappable_asset_ids', expires_in: 1.hour) do
        pairs['data']['pairs'].filter(&->(p) { (p['base_value'].to_f + p['quote_value'].to_f > 50_000) || p['swap_method'] == 'curve' }).map do |p|
          [p['base_asset_id'], p['quote_asset_id']]
        end.flatten.uniq
      end
    rescue StandardError
      []
    end

    def order(order_id, authorization:)
      path = "/api/orders/#{order_id}"
      client.get path, headers: { Authorization: authorization }
    end

    def actions(**options)
      path = '/api/actions'
      payload = {
        action: [3, options[:user_id], options[:follow_id], options[:asset_id], options[:route_id], options[:minimum_fill]].join(',')
      }
      client.post path, json: payload, headers: { Authorization: Rails.application.credentials.dig(:foxswap, :authorization) }
    end
  end
end
