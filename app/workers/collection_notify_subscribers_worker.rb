# frozen_string_literal: true

class CollectionNotifySubscribersWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform(id)
    Collection.find_by(id: id)&.notify_subscribers
  end
end
