# frozen_string_literal: true

module Foxswap
  class HttpError < StandardError; end

  class ResponseError < StandardError; end

  def self.api
    @api ||= Foxswap::API.new
  end
end
