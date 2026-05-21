# frozen_string_literal: true

require "test_helper"

class Transfers::CacheStatsJobTest < JobTestCase
  test "perform writes transfer stats to cache" do
    called = false

    stub_class_method(Transfer, :write_stats, -> { called = true }) do
      Transfers::CacheStatsJob.perform_now
    end

    assert called
  end
end
