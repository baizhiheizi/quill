# frozen_string_literal: true

module MVM
  class HttpError < StandardError; end

  class ResponseError < StandardError; end

  def self.api
    @api ||= MVM::API.new
  end
end
