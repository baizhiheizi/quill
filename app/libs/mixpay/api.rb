# frozen_string_literal: true

module Mixpay
  class API
    attr_reader :client

    def initialize
      @client = Client.new
    end

    def settlement_assets
      path = '/v1/setting/settlement_assets'
      client.get path
    end

    def quote_assets
      path = '/v1/setting/quote_assets'
      client.get path
    end

    def payments_result(trace_id)
      path = '/v1/payments_result'
      client.get(
        path,
        params: {
          traceId: trace_id
        }
      )
    end

    def payments_info(trace_id, client_id)
      path = '/v1/payments_info'
      client.get(
        path,
        params: {
          traceId: trace_id,
          clientId: client_id
        }
      )
    end

    def multisig(receivers, threshold)
      path = '/v1/multisig'

      client.post(
        path,
        json: {
          receivers:,
          threshold:
        }
      )
    end

    def quote_assets_cached
      Rails.cache.fetch('mixpay_quote_assets', expires_in: 10.minutes) do
        quote_assets
      end
    end

    def quote_asset_ids
      Rails.cache.fetch('mixpay_quote_asset_ids', expires_in: 10.minutes) do
        quote_assets.map(&->(asset) { asset['assetId'] })
      end
    end

    def settlement_asset_ids
      Rails.cache.fetch('mixpay_settlement_asset_ids', expires_in: 10.minutes) do
        settlement_assets.map(&->(asset) { asset['assetId'] })
      end
    end
  end
end
