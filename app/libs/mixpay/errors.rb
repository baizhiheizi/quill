# frozen_string_literal: true

module Mixpay
  module Errors
    Error = Class.new(StandardError)

    HttpError = Class.new(Error)
    APIError = Class.new(Error)
  end
end
