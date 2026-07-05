# frozen_string_literal: true

module MixinApi
  module Gate
    module_function

    CACHE_PREFIX = "mixin_api_gate"

    def enabled?
      settings.enabled != false
    rescue StandardError
      true
    end

    def acquire(scope, mode: :background)
      return unless enabled?

      mutex(scope).synchronize do
        wait_for_backoff!(scope)
        wait_for_interval!(scope)
      end
    end

    def release_success(scope)
      return unless enabled?

      mutex(scope).synchronize do
        write_cache(scope, :last_request_at, Time.current.iso8601(6))
        write_cache(scope, :backoff_attempt, 0)
      end
    end

    def record_throttle(scope, error)
      unless error.respond_to?(:throttle?) && error.throttle?
        raise ArgumentError, "expected MixinBot throttle error, got #{error.class}"
      end

      delay = nil
      mutex(scope).synchronize do
        attempt = read_cache(scope, :backoff_attempt).to_i + 1
        delay = backoff_delay(error, attempt)
        write_cache(scope, :backoff_until, (Time.current + delay).iso8601(6))
        write_cache(scope, :backoff_attempt, attempt)
        log_throttle(scope, error, delay)
      end
      delay
    end

    def record_retryable(scope, error)
      delay = nil
      mutex(scope).synchronize do
        attempt = read_cache(scope, :backoff_attempt).to_i + 1
        delay = exponential_backoff(attempt)
        write_cache(scope, :backoff_until, (Time.current + delay).iso8601(6))
        write_cache(scope, :backoff_attempt, attempt)
        log_retryable(scope, error, delay)
      end
      delay
    end

    def backoff_remaining(scope)
      until_time = read_cache(scope, :backoff_until)
      return 0.0 if until_time.blank?

      remaining = Time.iso8601(until_time) - Time.current
      remaining.positive? ? remaining : 0.0
    end

    def interactive_max_wait_seconds
      value = settings.interactive_max_wait_seconds
      value.to_i.positive? ? value.to_i : 5
    end

    def mutexes
      @mutexes ||= Hash.new { |hash, key| hash[key] = Mutex.new }
    end

    def mutex(scope)
      mutexes[scope.to_s]
    end

    def wait_for_backoff!(scope)
      remaining = backoff_remaining(scope)
      wait(remaining) if remaining.positive?
    end

    def wait_for_interval!(scope)
      last_at = read_cache(scope, :last_request_at)
      return if last_at.blank?

      interval = scope_min_interval_ms(scope) / 1000.0
      elapsed = Time.current - Time.iso8601(last_at)
      wait(interval - elapsed) if elapsed < interval
    end

    def wait(duration)
      sleep duration
    end

    def backoff_delay(error, attempt)
      retry_after = error.retry_after.to_f
      return retry_after if retry_after.positive?

      exponential_backoff(attempt)
    end

    def exponential_backoff(attempt)
      initial = settings.backoff.initial_seconds.to_f
      multiplier = settings.backoff.multiplier.to_f
      max_seconds = settings.backoff.max_seconds.to_f
      [ initial * (multiplier**(attempt - 1)), max_seconds ].min
    end

    def scope_min_interval_ms(scope)
      scopes = settings.scopes
      key =
        if scope.to_s.start_with?("user:")
          :user
        else
          scope.to_sym
        end

      scopes.public_send(key).min_interval_ms
    rescue StandardError
      250
    end

    def log_throttle(scope, error, delay)
      path = error.path.to_s.split("?").first
      Rails.logger.warn(
        format(
          "[MixinApi::Gate] scope=%<scope>s throttle verb=%<verb>s path=%<path>s backoff=%<backoff>.1fs retry_after=%<retry_after>s",
          scope: scope,
          verb: error.verb.to_s.upcase,
          path: path,
          backoff: delay,
          retry_after: error.retry_after.inspect
        )
      )
    end

    def log_retryable(scope, error, delay)
      Rails.logger.warn(
        format(
          "[MixinApi::Gate] scope=%<scope>s retryable error=%<error>s backoff=%<backoff>.1fs",
          scope: scope,
          error: error.class.name,
          backoff: delay
        )
      )
    end

    def cache_key(scope, suffix)
      "#{CACHE_PREFIX}:#{scope}:#{suffix}"
    end

    def read_cache(scope, suffix)
      Rails.cache.read(cache_key(scope, suffix))
    end

    def write_cache(scope, suffix, value)
      Rails.cache.write(cache_key(scope, suffix), value, expires_in: cache_ttl.seconds)
    end

    def cache_ttl
      settings.backoff.max_seconds.to_i + 60
    rescue StandardError
      120
    end

    def settings
      Settings.mixin_api_gate
    end
  end

  module_function

  def wrap(api, scope:, mode: :background)
    return api if api.blank? || !Gate.enabled?

    limited_client = RateLimitedClient.new(api.client, scope: scope, mode: mode)
    api.instance_variable_set(:@client, limited_client)
    api
  end
end
