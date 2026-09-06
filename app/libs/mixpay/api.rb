# frozen_string_literal: true

module Mixpay
  class API
    attr_reader :client

    def initialize
      @client = Client.new
    end

    def settlement_assets
      path = "/v1/setting/settlement_assets"
      client.get path
    end

    def quote_assets
      path = "/v1/setting/quote_assets"
      client.get path
    end

    def quote_assets_cached
      Rails.cache.fetch("mixpay_quote_assets", expires_in: 10.minutes, race_condition_ttl: 60.seconds) do
        quote_assets
      end
    end

    def settlement_asset_ids
      Rails.cache.fetch("mixpay_settlement_asset_ids", expires_in: 10.minutes, race_condition_ttl: 60.seconds) do
        settlement_assets.map(&->(asset) { asset["assetId"] })
      end
    end
  end
end
