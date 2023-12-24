# frozen_string_literal: true

class Transfers::CacheStatsJob < ApplicationJob
  def perform
    Transfer.write_stats
  end
end
