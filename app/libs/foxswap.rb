# frozen_string_literal: true

module Foxswap
  def self.api
    @api ||= Foxswap::API.new
  end
end
