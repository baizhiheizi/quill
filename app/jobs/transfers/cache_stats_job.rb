# frozen_string_literal: true

class Transfers::CacheStatsJob < ApplicationJob
  queue_as :low
  def perform
    Transfer.write_stats
  end
end
