# frozen_string_literal: true

class DailyStatistics::GenerateJob < ApplicationJob
  queue_as :low
  retry_on StandardError, attempts: 1

  def perform
    DailyStatistic.generate date: Time.current.yesterday
  end
end
