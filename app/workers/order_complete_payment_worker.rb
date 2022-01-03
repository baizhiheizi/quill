# frozen_string_literal: true

class OrderCompletePaymentWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: true

  def perform(id)
    Order.find_by(id: id)&.complete_payment
  end
end
