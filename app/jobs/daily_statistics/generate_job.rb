# frozen_string_literal: true

class DailyStatistics::GenerateJob < ApplicationJob
  queue_as :low
  # The blanket `retry_on StandardError, attempts: 1` override used to prevent
  # the old ApplicationJob 5× retry from re-running the whole daily report.
  # ApplicationJob now only retries known-transient errors (network, rate
  # limit, deadlocks) and discards permanent ones, so arbitrary StandardError
  # already fails once — the override is redundant. Transient failures during
  # report generation now get the base-class backoff instead of a hard stop.

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
