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
end
