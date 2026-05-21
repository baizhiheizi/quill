# frozen_string_literal: true

require "test_helper"

class MixinMessages::ProcessJobTest < JobTestCase
  test "perform no-ops for missing message" do
    assert_nothing_raised { MixinMessages::ProcessJob.perform_now(SecureRandom.uuid) }
  end

  test "perform calls process! on message" do
    message_id = SecureRandom.uuid
    message = MixinMessage.new(message_id: message_id)
    called = false
    message.define_singleton_method(:process!) { called = true }

    stub_class_method(MixinMessage, :find_by, ->(**kwargs) { kwargs[:message_id] == message_id ? message : nil }) do
      MixinMessages::ProcessJob.perform_now(message_id)
    end

    assert called
  end
end
