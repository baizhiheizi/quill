# frozen_string_literal: true

require "test_helper"

class AdminNotificationServiceTest < ActiveSupport::TestCase
  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # `AdminNotificationService` short-circuits when
  # `Rails.application.credentials.dig(:admin, :group_conversation_id)` is
  # blank (the test environment has no admin conversation configured). Tests
  # replace `credentials` with a tiny stand-in that responds to `.dig`.
  FakeCredentials = Struct.new(:group_conversation_id) do
    def dig(*keys)
      return group_conversation_id if keys == [ :admin, :group_conversation_id ]

      nil
    end
  end

  def with_admin_credentials(group_conversation_id: SecureRandom.uuid)
    original_credentials = Rails.application.credentials
    Rails.application.define_singleton_method(:credentials) do
      FakeCredentials.new(group_conversation_id)
    end
    yield
  ensure
    Rails.application.define_singleton_method(:credentials) { original_credentials }
  end

  def with_admin_credentials_blank
    with_admin_credentials(group_conversation_id: nil) { yield }
  end

  # ---------------------------------------------------------------------------
  # behavior
  # ---------------------------------------------------------------------------

  test "text no-ops when admin group_conversation_id is blank" do
    api_calls = []
    with_quill_bot_stub do
      api = Object.new
      api.define_singleton_method(:plain_text) { |conversation_id:, data:| api_calls << [ conversation_id, data ]; {} }
      QuillBot.define_singleton_method(:api) { api }

      with_admin_credentials_blank do
        AdminNotificationService.new.text("ignored")
      end
    end

    assert_empty api_calls
    assert_no_enqueued_jobs
  end

  test "text forwards payload to QuillBot.api.plain_text and enqueues SendJob" do
    api_calls = []

    with_quill_bot_stub do
      api = Object.new
      api.define_singleton_method(:plain_text) do |conversation_id:, data:|
        api_calls << { conversation_id: conversation_id, data: data }
        { "conversation_id" => conversation_id, "data" => data, "kind" => "PLAIN_TEXT" }
      end
      QuillBot.define_singleton_method(:api) { api }

      with_admin_credentials(group_conversation_id: "fixed-admin-conv") do
        assert_enqueued_with(job: MixinMessages::SendJob) do
          AdminNotificationService.new.text("an urgent notice")
        end
      end
    end

    assert_equal 1, api_calls.length
    assert_equal "fixed-admin-conv", api_calls.first[:conversation_id]
    assert_equal "an urgent notice", api_calls.first[:data]
  end

  test "text enqueue payload carries the conversation_id, data, and message kind" do
    captured_message = nil

    with_quill_bot_stub do
      api = Object.new
      api.define_singleton_method(:plain_text) do |conversation_id:, data:|
        captured_message = { "conversation_id" => conversation_id, "data" => data, "kind" => "PLAIN_TEXT" }
      end
      QuillBot.define_singleton_method(:api) { api }

      with_admin_credentials(group_conversation_id: "admin-conv-x") do
        assert_enqueued_with(job: MixinMessages::SendJob, args: [ { "conversation_id" => "admin-conv-x", "data" => "payload", "kind" => "PLAIN_TEXT" } ]) do
          AdminNotificationService.new.text("payload")
        end
      end
    end

    assert_equal "PLAIN_TEXT", captured_message["kind"]
  end
end
