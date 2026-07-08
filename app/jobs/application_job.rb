# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  MAX_TRANSIENT_RETRIES = 5
  TRANSIENT_RETRY_WAIT = 5.seconds

  # Discard permanent / expected failures — retrying them only fans the same
  # error out 5×. Each is reported so it surfaces without re-enqueuing.
  discard_on ActiveJob::DeserializationError,
             ActiveRecord::RecordNotFound,
             MixinBot::NotFoundError,
             MixinBot::UserNotFoundError,
             MixinBot::UnauthorizedError,
             MixinBot::ForbiddenError,
             MixinBot::ValidationError,
             MixinBot::ConflictError,
             MixinBot::InsufficientBalanceError,
             MixinBot::InsufficientPoolError,
             MixinBot::PinError,
             MixinBot::InvalidAddressFormatError do |job, error|
    ApplicationJob.report_discarded(job, error)
  end

  # Retry transient network / rate-limit / server failures with backoff.
  retry_on Faraday::TimeoutError,
           Faraday::ConnectionFailed,
           OpenSSL::SSL::SSLError,
           MixinBot::RateLimitError,
           MixinBot::TransientError,
           MixinBot::ServerError,
           wait: :polynomially_longer, attempts: MAX_TRANSIENT_RETRIES

  # Deadlocks deserve a shorter, bounded retry.
  retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3

  # Generic Mixin errors carry an error code that decides retryability
  # (see MixinBot.retryable?). Route them dynamically instead of blanket
  # retrying, so a 4xx-style unmapped error is discarded rather than retried.
  rescue_from MixinBot::ResponseError,
              MixinBot::RequestError,
              MixinBot::HttpError do |error|
    if executions < MAX_TRANSIENT_RETRIES && MixinBot.retryable?(error)
      retry_job(wait: TRANSIENT_RETRY_WAIT)
    else
      ApplicationJob.report_discarded(self, error)
    end
  end

  # Centralized discard logging + reporting. Kept resilient so a failure in the
  # error reporter itself can never raise out of a discard/retry handler.
  def self.report_discarded(job, error)
    Rails.logger.error "Discarded #{job.class.name} (#{error.class}): #{error.message}"
    Rails.error.report(error, handled: true, severity: :warning,
                       context: { job: job.class.name, arguments: job.arguments.inspect })
  rescue => e
    Rails.logger.error "Failed to report discarded job #{job.class.name}: #{e.class}"
  end
end
