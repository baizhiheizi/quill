# frozen_string_literal: true

module ArweaveBot
  class HttpError < StandardError; end
  class ResponseError < StandardError; end

  def self.api
    @api ||= ArweaveBot::API.new
  end

  def self.graphql
    @graphql ||= ArweaveBot::Graphql.new
  end
end
