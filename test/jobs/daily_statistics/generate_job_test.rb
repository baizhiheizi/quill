# frozen_string_literal: true

require "test_helper"

class DailyStatistics::GenerateJobTest < JobTestCase
  test "perform generates daily statistic" do
    generated = false

    stub_class_method(DailyStatistic, :generate, ->(**_kwargs) { generated = true }) do
      DailyStatistics::GenerateJob.perform_now
    end

    assert generated
  end
end
