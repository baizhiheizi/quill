# frozen_string_literal: true

module Prs
  class HttpError < StandardError; end

  class ResponseError < StandardError; end

  def self.api
    @api ||= Prs::API.new
  end
end
