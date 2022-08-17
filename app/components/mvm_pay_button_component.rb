# frozen_string_literal: true

class MVMPayButtonComponent < ApplicationComponent
  def initialize(**options)
    super

    @currency = options[:currency]
    @amount = options[:amount]
    @payer = options[:payer]
    @receivers = options[:receivers]
    @threshold = options[:threshold]
    @memo = options[:memo]
    @trace_id = options[:trace_id]
  end
end
