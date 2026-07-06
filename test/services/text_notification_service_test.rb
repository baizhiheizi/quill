# frozen_string_literal: true

require "test_helper"

class TextNotificationServiceTest < ActiveSupport::TestCase
  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # Captures calls into `QuillBot.api.plain_text` so tests can assert on the
  # `conversation_id` resolution and the forwarded `data` payload.
  def stubbed_api(captured, resolved_conversation_id_for: ->(parts) { "conv-for-#{parts.compact.join('-')}" })
    api = Object.new
    api.define_singleton_method(:unique_conversation_id) do |*parts|
      captured << [ :unique_conversation_id, parts ]
      resolved_conversation_id_for.call(parts)
    end
    api.define_singleton_method(:plain_text) do |conversation_id:, data:|
      captured << [ :plain_text, { conversation_id: conversation_id, data: data } ]
      { "conversation_id" => conversation_id, "data" => data }
    end
    api
  end

  # ---------------------------------------------------------------------------
  # behavior
  # ---------------------------------------------------------------------------

  test "calls QuillBot.api.plain_text with the per-recipient conversation_id" do
    captured = []
    api = stubbed_api(captured, resolved_conversation_id_for: ->(_parts) { "conv-fixed" })

    with_quill_bot_stub do
      QuillBot.define_singleton_method(:api) { api }

      TextNotificationService.new.call("hello", recipient_id: "recipient-uuid-1234")
    end

    plain_text_calls = captured.select { |c| c.first == :plain_text }
    assert_equal 1, plain_text_calls.length
    assert_equal "conv-fixed", plain_text_calls.first.last[:conversation_id]
    assert_equal "hello", plain_text_calls.first.last[:data]
  end

  test "forwards the recipient_id to unique_conversation_id exactly once per call" do
    captured = []
    api = stubbed_api(captured)

    with_quill_bot_stub do
      QuillBot.define_singleton_method(:api) { api }

      TextNotificationService.new.call("hi", recipient_id: "the-recipient")
    end

    conversation_id_calls = captured.select { |c| c.first == :unique_conversation_id }
    assert_equal 1, conversation_id_calls.length
    assert_equal [ "the-recipient" ], conversation_id_calls.first.last
  end

  test "two calls with different recipient_ids produce different conversation_ids" do
    captured = []
    resolver = ->(parts) { "conv-#{parts.first}" }
    api = stubbed_api(captured, resolved_conversation_id_for: resolver)

    with_quill_bot_stub do
      QuillBot.define_singleton_method(:api) { api }

      TextNotificationService.new.call("hi", recipient_id: "alice")
      TextNotificationService.new.call("hi", recipient_id: "bob")
    end

    conversation_id_calls = captured.select { |c| c.first == :unique_conversation_id }
    assert_equal 2, conversation_id_calls.length

    plain_text_calls = captured.select { |c| c.first == :plain_text }
    assert_equal "conv-alice", plain_text_calls.first.last[:conversation_id]
    assert_equal "conv-bob", plain_text_calls.last.last[:conversation_id]
  end

  test "enqueues MixinMessages::SendJob with the message hash from plain_text" do
    captured = []
    api = stubbed_api(captured, resolved_conversation_id_for: ->(_parts) { "conv-xyz" })

    with_quill_bot_stub do
      QuillBot.define_singleton_method(:api) { api }

      assert_enqueued_with(
        job: MixinMessages::SendJob,
        args: [ { "conversation_id" => "conv-xyz", "data" => "broadcast" } ]
      ) do
        TextNotificationService.new.call("broadcast", recipient_id: "user-abc")
      end
    end
  end

  test "enqueues one SendJob per call" do
    captured = []
    api = stubbed_api(captured)

    with_quill_bot_stub do
      QuillBot.define_singleton_method(:api) { api }

      assert_enqueued_jobs 3, only: MixinMessages::SendJob do
        3.times { |i| TextNotificationService.new.call("msg-#{i}", recipient_id: "user-#{i}") }
      end
    end
  end

  test "data payload is passed straight through to plain_text and into the SendJob message" do
    captured_message = nil

    api = Object.new
    api.define_singleton_method(:unique_conversation_id) { |*_| "conv-fixed" }
    api.define_singleton_method(:plain_text) do |conversation_id:, data:|
      captured_message = { "conversation_id" => conversation_id, "data" => data }
    end

    with_quill_bot_stub do
      QuillBot.define_singleton_method(:api) { api }

      assert_enqueued_with(job: MixinMessages::SendJob, args: [ { "conversation_id" => "conv-fixed", "data" => "verbatim-payload" } ]) do
        TextNotificationService.new.call("verbatim-payload", recipient_id: "any-user")
      end
    end

    assert_equal "verbatim-payload", captured_message["data"]
    assert_equal "conv-fixed", captured_message["conversation_id"]
  end

  test "result returned by plain_text is what gets handed to SendJob verbatim" do
    custom_message = { "conversation_id" => "round-trip", "data" => "long-form", "extra" => "metadata" }

    api = Object.new
    api.define_singleton_method(:unique_conversation_id) { |*_| "round-trip" }
    api.define_singleton_method(:plain_text) { |conversation_id:, data:| custom_message }

    with_quill_bot_stub do
      QuillBot.define_singleton_method(:api) { api }

      assert_enqueued_with(job: MixinMessages::SendJob, args: [ custom_message ]) do
        TextNotificationService.new.call("long-form", recipient_id: "any-user")
      end
    end
  end

  test "SendJob gets the .stringify_keys-applied hash (string keys, symbol values preserved)" do
    captured_job_args = []

    # Capture by performing the enqueued job using a stubbed send_message.
    api = Object.new
    api.define_singleton_method(:unique_conversation_id) { |*_| "capture-conv" }
    api.define_singleton_method(:plain_text) do |conversation_id:, data:|
      { "conversation_id" => conversation_id, "data" => data }
    end
    api.define_singleton_method(:send_message) { |msg| captured_job_args << msg }

    with_quill_bot_stub do
      QuillBot.define_singleton_method(:api) { api }

      assert_performed_jobs(1, only: MixinMessages::SendJob) do
        TextNotificationService.new.call("performed-payload", recipient_id: "user-1")
      end
    end

    assert_equal 1, captured_job_args.length
    msg = captured_job_args.first
    assert_kind_of Hash, msg
    assert_equal "capture-conv", msg["conversation_id"]
    assert_equal "performed-payload", msg["data"]
  end
end
