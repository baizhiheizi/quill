# frozen_string_literal: true

class Transfers::CacheStatsJob
  include Sidekiq::Job
  sidekiq_options retry: false

  def perform
    Transfer.write_stats
  end
end
