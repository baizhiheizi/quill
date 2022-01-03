# frozen_string_literal: true

class OrderNotifyWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform(id)
    Order.find_by(id: id)&.notify
  end
end
