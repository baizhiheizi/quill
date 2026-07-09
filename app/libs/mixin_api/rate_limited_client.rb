# frozen_string_literal: true

module MixinApi
  class RateLimitedClient
    HTTP_METHODS = %i[get post fetch_get fetch_post fetch_post_array].freeze

    def initialize(inner, scope:, mode: :background)
      @inner = inner
      @scope = scope
      @mode = mode
    end

    HTTP_METHODS.each do |method_name|
      define_method(method_name) do |*args, **kwargs, &block|
        execute { @inner.public_send(method_name, *args, **kwargs, &block) }
      end
    end

    private

    def execute
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      attempts = 0

      loop do
        Gate.acquire(@scope, mode: @mode)
        begin
          result = yield
          Gate.release_success(@scope)
          return result
        rescue MixinBot::RateLimitError => e
          Gate.record_throttle(@scope, e)
          attempts += 1
          raise e if should_re_raise_throttle?(started_at, attempts)
        rescue StandardError => e
          raise e unless background_retryable?(e)

          Gate.record_retryable(@scope, e)
          attempts += 1
          raise e if background_exhausted?(started_at, attempts)
        end
      end
    end

    def interactive?
      @mode == :interactive
    end

    def background?
      @mode == :background
    end

    def should_re_raise_throttle?(started_at, attempts)
      if interactive?
        interactive_exhausted?(started_at)
      else
        background_exhausted?(started_at, attempts)
      end
    end

    def interactive_exhausted?(started_at)
      Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at >= Gate.interactive_max_wait_seconds
    end

    def background_exhausted?(started_at, attempts)
      return false unless background?

      attempts >= Gate.background_max_attempts ||
        (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) >= Gate.background_max_wait_seconds
    end

    def background_retryable?(error)
      background? && MixinBot.retryable?(error)
    end
  end
end
