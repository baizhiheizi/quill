# frozen_string_literal: true

module Mixpay
  def self.api
    @api ||= Mixpay::API.new
  end
end
