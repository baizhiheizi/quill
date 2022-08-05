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
          receivers: receivers,
          threshold: threshold
        }
      )
    end

    def settlement_asset_ids
      Rails.cache.fetch('mixpay_settlement_asset_ids', expires_in: 1.day) do
        settlement_assets.map(&->(asset) { asset['assetId'] })
      end
    end
  end
end
