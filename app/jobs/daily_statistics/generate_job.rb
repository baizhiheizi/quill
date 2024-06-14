# frozen_string_literal: true

class DailyStatistics::GenerateJob < ApplicationJob
  queue_as :low
  retry_on StandardError, attempts: 1

  def perform
    DailyStatistic.generate date: Time.current.yesterday

    conversation_id = Rails.application.credentials.dig(:mixin_groups, :operation)
    return if conversation_id.blank?

    report = QuillBot.api.plain_post(
      conversation_id:,
      data: QuillBot.generate_app_report
    )

    MixinMessages::SendJob.perform_later report
  end
end
