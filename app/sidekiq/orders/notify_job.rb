# frozen_string_literal: true

class Orders::NotifyJob
  include Sidekiq::Job
  sidekiq_options queue: :default

  def perform(id)
    Order.find_by(id: id)&.notify
  end
end
