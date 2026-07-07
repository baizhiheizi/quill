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

  test "post forwards payload even when admin group_conversation_id is blank (documents existing behavior)" do
    # NOTE: `AdminNotificationService#text` short-circuits on a blank admin
    # credentials value, but `#post` does NOT — it always calls `plain_post`.
    # Locking that asymmetry in as a test so future refactors won't change
    # the behavior silently.
    api_calls = []
    with_quill_bot_stub do
      api = Object.new
      api.define_singleton_method(:plain_post) { |conversation_id:, data:| api_calls << [ conversation_id, data ]; {} }
      QuillBot.define_singleton_method(:api) { api }

      with_admin_credentials_blank do
        AdminNotificationService.new.post("post-ignored")
      end
    end

    assert_equal 1, api_calls.length
    assert_nil api_calls.first.first, "expected nil conversation_id when credentials are blank"
    assert_equal "post-ignored", api_calls.first.last
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

  test "post forwards payload to QuillBot.api.plain_post and enqueues SendJob" do
    api_calls = []

    with_quill_bot_stub do
      api = Object.new
      api.define_singleton_method(:plain_post) do |conversation_id:, data:|
        api_calls << { conversation_id: conversation_id, data: data }
        { "conversation_id" => conversation_id, "data" => data, "kind" => "PLAIN_POST" }
      end
      QuillBot.define_singleton_method(:api) { api }

      with_admin_credentials(group_conversation_id: "admin-conv-y") do
        assert_enqueued_with(job: MixinMessages::SendJob) do
          AdminNotificationService.new.post("deploy v1.2.3")
        end
      end
    end

    assert_equal 1, api_calls.length
    assert_equal "admin-conv-y", api_calls.first[:conversation_id]
    assert_equal "deploy v1.2.3", api_calls.first[:data]
  end

  test "text and post share the same admin conversation_id source" do
    api_calls = []

    with_quill_bot_stub do
      api = Object.new
      api.define_singleton_method(:plain_text) do |conversation_id:, data:|
        api_calls << [ :text, conversation_id, data ]
        { "conversation_id" => conversation_id, "data" => data, "kind" => "PLAIN_TEXT" }
      end
      api.define_singleton_method(:plain_post) do |conversation_id:, data:|
        api_calls << [ :post, conversation_id, data ]
        { "conversation_id" => conversation_id, "data" => data, "kind" => "PLAIN_POST" }
      end
      QuillBot.define_singleton_method(:api) { api }

      with_admin_credentials(group_conversation_id: "shared-conv") do
        AdminNotificationService.new.text("a")
        AdminNotificationService.new.post("b")
      end
    end

    assert_equal 2, api_calls.length
    assert_equal [ :text, "shared-conv", "a" ], api_calls.first
    assert_equal [ :post, "shared-conv", "b" ], api_calls.last
    assert_equal 2, enqueued_jobs.length
    assert_equal MixinMessages::SendJob, enqueued_jobs.first[:job]
  end

  test "post payload (Hash) is preserved through plain_post and into the enqueued SendJob" do
    captured_message = nil
    post_payload = { headline: "Deploy v2.0", body: "scheduled maintenance" }

    with_quill_bot_stub do
      api = Object.new
      api.define_singleton_method(:plain_post) do |conversation_id:, data:|
        captured_message = { "conversation_id" => conversation_id, "data" => data, "kind" => "PLAIN_POST" }
      end
      QuillBot.define_singleton_method(:api) { api }

      with_admin_credentials(group_conversation_id: "post-conv") do
        assert_enqueued_with(job: MixinMessages::SendJob, args: [ { "conversation_id" => "post-conv", "data" => post_payload, "kind" => "PLAIN_POST" } ]) do
          AdminNotificationService.new.post(post_payload)
        end
      end
    end

    assert_equal post_payload, captured_message["data"]
  end
end
