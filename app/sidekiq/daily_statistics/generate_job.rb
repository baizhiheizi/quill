# frozen_string_literal: true

class DailyStatistics::GenerateJob
  include Sidekiq::Job
  sidekiq_options queue: :low, retry: false

  def perform
    DailyStatistic.generate date: Time.current.yesterday
  end
end
