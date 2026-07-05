# frozen_string_literal: true

require "test_helper"

class ExceptionNotifier::MixinBotNotifierTest < ActiveSupport::TestCase
  include QuillBotStub
  include ActiveJob::TestHelper

  setup do
    @notifier = ExceptionNotifier::MixinBotNotifier.new(
      conversation_id: SecureRandom.uuid,
      bot: "QuillBot"
    )
  end

  test "call skips RateLimitError without enqueueing SendJob" do
    error = MixinBot::RateLimitError.new(
      code: 429,
      description: "Too Many Requests",
      verb: "GET",
      path: "/safe/snapshots"
    )

    assert_no_enqueued_jobs(only: MixinMessages::SendJob) do
      @notifier.call(error)
    end
  end

  test "call enqueues SendJob for unrelated errors" do
    error = StandardError.new("database unavailable")

    with_quill_bot_stub do
      QuillBot.api.define_singleton_method(:plain_post) do |conversation_id:, data:, recipient_id: nil|
        {
          "conversation_id" => conversation_id,
          "recipient_id" => recipient_id,
          "data" => data,
          "category" => "PLAIN_POST"
        }
      end

      assert_enqueued_with(job: MixinMessages::SendJob) do
        @notifier.call(error)
      end
    end
  end
end
