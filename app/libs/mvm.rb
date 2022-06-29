# frozen_string_literal: true

module MVM
  class Error < StandardError; end
  class HttpError < Error; end
  class ResponseError < Error; end

  def self.api
    @api ||= MVM::API.new
  end
end
