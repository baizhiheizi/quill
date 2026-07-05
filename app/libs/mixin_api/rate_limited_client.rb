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
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC) if interactive?

      loop do
        Gate.acquire(@scope, mode: @mode)
        begin
          result = yield
          Gate.release_success(@scope)
          return result
        rescue MixinBot::RateLimitError => e
          Gate.record_throttle(@scope, e)
          raise e if interactive? && interactive_exhausted?(started_at)
        rescue StandardError => e
          raise e unless background_retryable?(e)

          Gate.record_retryable(@scope, e)
        end
      end
    end

    def interactive?
      @mode == :interactive
    end

    def interactive_exhausted?(started_at)
      Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at >= Gate.interactive_max_wait_seconds
    end

    def background_retryable?(error)
      @mode == :background && MixinBot.retryable?(error)
    end
  end
end
