# frozen_string_literal: true

class UserPrepareWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: true

  def perform(id)
    User.find_by(id: id)&.prepare
  end
end
