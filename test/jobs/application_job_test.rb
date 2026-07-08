# frozen_string_literal: true

require "test_helper"

# A concrete job that raises an error identified by a symbol, so we can
# exercise the ApplicationJob retry/discard matrix without coupling to a real
# job and without passing non-serializable error objects as arguments.
class MatrixProbeJob < ApplicationJob
  ERRORS = {
    record_not_found: -> { ActiveRecord::RecordNotFound.new("missing") },
    forbidden: -> { MixinBot::ForbiddenError.new("perm") },
    unauthorized: -> { MixinBot::UnauthorizedError.new("perm") },
    not_found: -> { MixinBot::NotFoundError.new("perm") },
    insufficient_balance: -> { MixinBot::InsufficientBalanceError.new("perm") },
    timeout: -> { Faraday::TimeoutError.new("timeout") },
    connection_failed: -> { Faraday::ConnectionFailed.new("conn") },
    response_500: -> { MixinBot::ResponseError.new("server", code: 500) },
    response_400: -> { MixinBot::ResponseError.new("client", code: 400) }
  }.freeze

  def perform(key)
    raise ERRORS.fetch(key).call
  end
end

class ApplicationJobTest < JobTestCase
  test "discards ActiveRecord::RecordNotFound without retrying" do
    assert_no_enqueued_jobs do
      MatrixProbeJob.perform_now(:record_not_found)
    end
  end

  test "discards permanent MixinBot client errors without retrying" do
    [ :forbidden, :unauthorized, :not_found, :insufficient_balance ].each do |key|
      assert_no_enqueued_jobs do
        MatrixProbeJob.perform_now(key)
      end
    end
  end

  test "retries Faraday network errors by re-enqueuing" do
    MatrixProbeJob.perform_now(:timeout)
    # discard_on swallows; retry_on re-enqueues. TimeoutError is retried, so a
    # fresh job should be enqueued for the next attempt.
    assert enqueued_jobs.any? { |j| j["job_class"] == "MatrixProbeJob" },
           "transient Faraday::TimeoutError should re-enqueue for retry"
  end

  test "dynamic MixinBot::ResponseError routes by retryability" do
    clear_enqueued_jobs

    # 500 → retryable → re-enqueue
    MatrixProbeJob.perform_now(:response_500)
    assert enqueued_jobs.any? { |j| j["job_class"] == "MatrixProbeJob" },
           "retryable ResponseError (500) should re-enqueue"

    clear_enqueued_jobs

    # 400 → not retryable → discard, no enqueue
    MatrixProbeJob.perform_now(:response_400)
    assert_no_enqueued_jobs
  end
end
