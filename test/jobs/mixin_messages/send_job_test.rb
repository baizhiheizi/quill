# frozen_string_literal: true

require "test_helper"

class MixinMessages::SendJobTest < JobTestCase
  test "perform sends message via QuillBot" do
    message = { "conversation_id" => SecureRandom.uuid }
    called = false
    api = Object.new
    api.define_singleton_method(:send_message) { |payload| called = payload == message }

    original_api = QuillBot.api
    QuillBot.define_singleton_method(:api) { api }
    MixinMessages::SendJob.perform_now(message)
    assert called
  ensure
    QuillBot.define_singleton_method(:api) { original_api }
  end

  test "perform sends message via RevenueBot when requested" do
    message = { "conversation_id" => SecureRandom.uuid }
    called = false
    api = Object.new
    api.define_singleton_method(:send_message) { |payload| called = payload == message }

    original_api = RevenueBot.api
    RevenueBot.define_singleton_method(:api) { api }
    MixinMessages::SendJob.perform_now(message, "RevenueBot")
    assert called
  ensure
    RevenueBot.define_singleton_method(:api) { original_api }
  end
end
