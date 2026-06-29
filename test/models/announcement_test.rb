# frozen_string_literal: true

# == Schema Information
#
# Table name: announcements
# Database name: primary
#
#  id           :bigint           not null, primary key
#  content      :text
#  delivered_at :datetime
#  message_type :string
#  state        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require "test_helper"

class AnnouncementTest < ActiveSupport::TestCase
  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # `Announcement#preview` (and the delegated `AdminNotificationService`) short-
  # circuit on `Rails.application.credentials.dig(:admin, :group_conversation_id)`.
  # In the test environment that value is nil, so we replace `credentials` with
  # a Struct that responds to `.dig` and returns whatever the test needs.
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

  def make_user_with_mixin_uuid(name: "delivery target")
    User.create!(
      name: name,
      uid: SecureRandom.hex(8),
      mixin_uuid: SecureRandom.uuid,
      mixin_id: SecureRandom.hex(4)
    )
  end

  # Captures the `data:` payloads passed to `QuillBot.api.plain_text` (or
  # `plain_post`) so tests can assert on what the announcement broadcast.
  def capture_api_calls(api_method, hash: {})
    captured = []
    QuillBot.api.define_singleton_method(api_method) do |conversation_id:, recipient_id: nil, data:|
      captured << { conversation_id: conversation_id, recipient_id: recipient_id, data: data }
      hash.fetch(:return_value) { { "message_id" => SecureRandom.uuid, "conversation_id" => conversation_id, "recipient_id" => recipient_id, "data" => data } }
    end
    captured
  end

  # ---------------------------------------------------------------------------
  # Validations
  # ---------------------------------------------------------------------------

  test "requires content" do
    announcement = Announcement.new(message_type: "PLAIN_TEXT")

    assert_not announcement.valid?
    assert_includes announcement.errors[:content], "can't be blank"
  end

  test "requires message_type" do
    announcement = Announcement.new(content: "hello")

    assert_not announcement.valid?
    assert_includes announcement.errors[:message_type], "can't be blank"
  end

  # ---------------------------------------------------------------------------
  # AASM
  # ---------------------------------------------------------------------------

  test "initial state is draft" do
    announcement = Announcement.new(content: "x", message_type: "PLAIN_TEXT")

    assert_predicate announcement, :draft?
    assert_not announcement.delivered?
  end

  test "deliver! transitions to delivered and stamps delivered_at" do
    freeze_time = Time.current

    travel_to(freeze_time) do
      announcement = Announcement.create!(content: "x", message_type: "PLAIN_TEXT")
      announcement.deliver!
      announcement.reload

      assert_predicate announcement, :delivered?
      assert_in_delta freeze_time.to_f, announcement.delivered_at.to_f, 1.0
    end
  end

  test "deliver! from delivered state raises AASM::InvalidTransition" do
    announcement = Announcement.create!(content: "x", message_type: "PLAIN_TEXT")
    announcement.deliver!

    assert_raises(AASM::InvalidTransition) { announcement.deliver! }
  end

  test "touch_delivered_at updates delivered_at column" do
    announcement = Announcement.create!(content: "x", message_type: "PLAIN_TEXT")
    freeze_time = Time.current

    travel_to(freeze_time) do
      announcement.touch_delivered_at
      announcement.reload

      assert_in_delta freeze_time.to_f, announcement.delivered_at.to_f, 1.0
    end
  end

  # ---------------------------------------------------------------------------
  # #preview (delegates to AdminNotificationService)
  # ---------------------------------------------------------------------------

  test "preview returns nil when admin group conversation credential is blank" do
    announcement = Announcement.new(content: "hello", message_type: "PLAIN_TEXT")

    with_admin_credentials_blank do
      assert_nil announcement.preview
    end
  end

  test "preview returns nil when message_type is unknown" do
    announcement = Announcement.new(content: "hello", message_type: "RICH_TEXT")

    with_admin_credentials do
      assert_nil announcement.preview
    end
  end

  test "preview for PLAIN_TEXT calls QuillBot.api.plain_text and enqueues SendJob" do
    announcement = Announcement.new(content: "hello world", message_type: "PLAIN_TEXT")

    api_calls = []

    with_admin_credentials(group_conversation_id: "conv-123") do
      with_quill_bot_stub do
        QuillBot.api.define_singleton_method(:plain_text) do |conversation_id:, recipient_id: nil, data:|
          api_calls << { conversation_id: conversation_id, data: data }
          { "conversation_id" => conversation_id, "recipient_id" => recipient_id, "data" => data, "message_id" => "msg-1" }
        end

        # `preview` returns the result of `perform_later`, which is a Job
        # instance in the test adapter. The contract we pin is what the API
        # was called with — that's the actual message payload.
        announcement.preview
      end
    end

    assert_equal 1, api_calls.size
    assert_equal "conv-123", api_calls.first[:conversation_id]
    assert_equal "hello world", api_calls.first[:data]
    assert_enqueued_jobs 1, only: MixinMessages::SendJob
  end

  test "preview for PLAIN_POST calls QuillBot.api.plain_post and enqueues SendJob" do
    announcement = Announcement.new(content: "rich body", message_type: "PLAIN_POST")

    api_calls = []

    with_admin_credentials(group_conversation_id: "conv-post") do
      with_quill_bot_stub do
        QuillBot.api.define_singleton_method(:plain_post) do |conversation_id:, recipient_id: nil, data:|
          api_calls << { conversation_id: conversation_id, data: data }
          { "conversation_id" => conversation_id, "recipient_id" => recipient_id, "data" => data, "message_id" => "post-1" }
        end

        announcement.preview
      end
    end

    assert_equal 1, api_calls.size
    assert_equal "conv-post", api_calls.first[:conversation_id]
    assert_equal "rich body", api_calls.first[:data]
    assert_enqueued_jobs 1, only: MixinMessages::SendJob
  end

  # ---------------------------------------------------------------------------
  # #deliver_to_users dispatch
  # ---------------------------------------------------------------------------

  test "deliver_to_users for PLAIN_TEXT calls plain_text once per user with mixin_uuid" do
    expected_users = User.where.not(mixin_uuid: nil).pluck(:mixin_uuid)
    announcement = Announcement.create!(content: "broadcast", message_type: "PLAIN_TEXT")

    captured = nil

    with_quill_bot_stub do
      captured = capture_api_calls(:plain_text)
      announcement.deliver_to_users
    end

    # Exactly one MixinMessages::SendJob is enqueued because `deliver_as_text`
    # batches via `in_groups_of(100, false)` — flipping the batch size would
    # silently spike the Mixin API.
    assert_equal expected_users.size, captured.size
    assert_equal expected_users.sort, captured.map { |c| c[:recipient_id] }.sort
    assert_equal "broadcast", captured.first[:data]
    assert_enqueued_jobs 1, only: MixinMessages::SendJob
  end

  test "deliver_to_users for PLAIN_POST calls plain_post once per user with mixin_uuid" do
    expected_users = User.where.not(mixin_uuid: nil).pluck(:mixin_uuid)
    announcement = Announcement.create!(content: "broadcast-post", message_type: "PLAIN_POST")

    captured = nil

    with_quill_bot_stub do
      captured = capture_api_calls(:plain_post)
      announcement.deliver_to_users
    end

    assert_equal expected_users.size, captured.size
    assert_equal expected_users.sort, captured.map { |c| c[:recipient_id] }.sort
    assert_equal "broadcast-post", captured.first[:data]
    # `deliver_as_post` enqueues one SendJob per message (no batching),
    # unlike `deliver_as_text` which batches in groups of 100.
    assert_enqueued_jobs expected_users.size, only: MixinMessages::SendJob
  end

  test "deliver_to_users passes the recipient's own conversation_id (not the admin one)" do
    # The preview path uses the admin group conversation; deliver_to_users uses
    # the recipient's own unique conversation. This is the contract that
    # separates the two flows and keeps the announcement out of the user's
    # personal inbox from the admin's broadcast.
    make_user_with_mixin_uuid

    announcement = Announcement.create!(content: "personal", message_type: "PLAIN_TEXT")
    captured = nil

    with_quill_bot_stub do
      captured = capture_api_calls(:plain_text)
      announcement.deliver_to_users
    end

    # QuillBotStub#unique_conversation_id returns Digest::UUID.uuid_v5(URL, parts.join("-"))
    # which is a stable UUID; the only contract we pin is that the conversation
    # id is NOT the admin group id and matches the recipient id.
    refute_empty captured
    captured.each do |call|
      expected_conversation = Digest::UUID.uuid_v5(Digest::UUID::URL_NAMESPACE, call[:recipient_id])
      assert_equal expected_conversation, call[:conversation_id]
    end
  end

  test "deliver_to_users transitions to delivered state and stamps delivered_at" do
    announcement = Announcement.create!(content: "broadcast", message_type: "PLAIN_TEXT")
    assert_predicate announcement, :draft?

    freeze_time = Time.current

    with_quill_bot_stub do
      capture_api_calls(:plain_text)

      travel_to(freeze_time) do
        announcement.deliver_to_users
        announcement.reload
      end
    end

    assert_predicate announcement, :delivered?
    assert_in_delta freeze_time.to_f, announcement.delivered_at.to_f, 1.0
  end

  test "deliver_to_users enqueues no jobs when there are no users at all" do
    # Delete every user so `User.pluck(:mixin_uuid)` returns `[]`. Other tests
    # are unaffected because Rails wraps each test in a transaction.
    User.delete_all
    Announcement.create!(content: "broadcast", message_type: "PLAIN_TEXT").deliver_to_users

    assert_no_enqueued_jobs only: MixinMessages::SendJob
  end

  test "deliver_to_users with unknown message_type still transitions AASM but enqueues nothing" do
    announcement = Announcement.create!(content: "broadcast", message_type: "RICH_TEXT")

    assert_nothing_raised { announcement.deliver_to_users }

    assert_predicate announcement.reload, :delivered?
    assert_no_enqueued_jobs only: MixinMessages::SendJob
  end

  test "deliver_as_text batches via in_groups_of(100, false) so the job count matches batches" do
    # With N < 100 users, in_groups_of(100, false) yields exactly one non-empty
    # batch, so deliver_as_text enqueues exactly one MixinMessages::SendJob
    # even though User.pluck(:mixin_uuid) returns N rows. This pins the 100-row
    # batching contract — flipping it to one-job-per-user would silently spike
    # the Mixin API for large announcements.
    announcement = Announcement.create!(content: "broadcast", message_type: "PLAIN_TEXT")

    with_quill_bot_stub do
      capture_api_calls(:plain_text)
      announcement.deliver_as_text
    end

    user_count = User.where.not(mixin_uuid: nil).count
    expected_batches = user_count.zero? ? 0 : 1

    assert_enqueued_jobs expected_batches, only: MixinMessages::SendJob
  end
end
