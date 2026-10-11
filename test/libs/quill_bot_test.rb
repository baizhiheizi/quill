# frozen_string_literal: true

require "test_helper"

class QuillBotTest < ActiveSupport::TestCase
  test "api raises ClientUnavailableError when the client fails to build" do
    original_api = QuillBot.method(:api)
    QuillBot.instance_variable_set(:@api, nil)
    original_build_api = QuillBot.method(:build_api)
    QuillBot.define_singleton_method(:build_api) { raise StandardError, "boom" }

    error = assert_raises(QuillBot::ClientUnavailableError) { QuillBot.api }
    assert_equal "boom", error.message
  ensure
    QuillBot.define_singleton_method(:api, original_api)
    QuillBot.define_singleton_method(:build_api, original_build_api)
    QuillBot.private_class_method(:build_api)
    QuillBot.instance_variable_set(:@api, nil)
  end

  test "interactive_api raises ClientUnavailableError when the client fails to build" do
    original = QuillBot.method(:build_api)
    QuillBot.define_singleton_method(:build_api) { raise StandardError, "boom" }

    assert_raises(QuillBot::ClientUnavailableError) { QuillBot.interactive_api }
  ensure
    QuillBot.define_singleton_method(:build_api, original)
    QuillBot.private_class_method(:build_api)
  end

  # --- blaze_reactor ---------------------------------------------------------

  test "blaze_reactor acknowledges only after the handler has run" do
    with_quill_bot_stub do
      assert_equal :after_handler, QuillBot.blaze_reactor.ack_policy
    end
  end

  test "blaze_reactor handler persists the envelope through MixinMessage.ingest!" do
    payload = {
      "action" => "CREATE_MESSAGE",
      "data" => {
        "message_id" => SecureRandom.uuid,
        "category" => "PLAIN_TEXT",
        "user_id" => SecureRandom.uuid,
        "data" => "hello"
      }
    }

    with_quill_bot_stub do
      msg = QuillBot.blaze_reactor.handler.call(payload)

      assert_equal payload["data"]["message_id"], msg.message_id
    end
  end
end
