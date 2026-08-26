# frozen_string_literal: true

require "test_helper"

class QuillBotTest < ActiveSupport::TestCase
  test "api raises ClientUnavailableError when the client fails to build" do
    QuillBot.instance_variable_set(:@api, nil)
    original = QuillBot.method(:build_api)
    QuillBot.define_singleton_method(:build_api) { raise StandardError, "boom" }

    error = assert_raises(QuillBot::ClientUnavailableError) { QuillBot.api }
    assert_equal "boom", error.message
  ensure
    QuillBot.define_singleton_method(:build_api, original)
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
end
