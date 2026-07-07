# frozen_string_literal: true

# == Schema Information
#
# Table name: mixin_messages
# Database name: primary
#
#  id                      :bigint           not null, primary key
#  action                  :string
#  category                :string
#  content(decrepted data) :string
#  processed_at            :datetime
#  raw                     :json
#  state                   :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  conversation_id         :uuid
#  message_id              :uuid
#  user_id                 :uuid
#
# Indexes
#
#  index_mixin_messages_on_message_id  (message_id) UNIQUE
#

require "test_helper"

class MixinMessageTest < ActiveSupport::TestCase
  def raw_payload(overrides = {})
    {
      "action" => "CREATE_MESSAGE",
      "data" => {
        "message_id" => SecureRandom.uuid,
        "category" => "PLAIN_TEXT",
        "conversation_id" => SecureRandom.uuid,
        "user_id" => SecureRandom.uuid,
        "data" => "Hello world"
      }
    }.deep_merge(overrides)
  end

  def build_message(overrides = {})
    msg = MixinMessage.new(raw: raw_payload(overrides.delete(:raw_overrides) || {}))
    # Stub setup_attributes so validation tests can leave `raw` nil safely.
    msg.define_singleton_method(:setup_attributes) { } if overrides.delete(:stub_setup)
    msg.assign_attributes(overrides)
    msg
  end

  # --- validations ------------------------------------------------------------

  test "is invalid without message_id" do
    msg = build_message(stub_setup: true, message_id: nil)
    assert_not msg.valid?
    assert_includes msg.errors[:message_id], "can't be blank"
  end

  test "is invalid without raw" do
    msg = MixinMessage.new
    # Leave `raw` nil; setup_attributes would crash trying to read raw["data"].
    msg.define_singleton_method(:setup_attributes) { }
    assert_not msg.valid?
    assert_includes msg.errors[:raw], "can't be blank"
  end

  test "is invalid with a duplicate message_id" do
    payload = raw_payload("data" => { "message_id" => SecureRandom.uuid })
    MixinMessage.create!(raw: payload)
    duplicate = MixinMessage.new(raw: payload)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:message_id], "has already been taken"
  end

  # --- setup_attributes callback ---------------------------------------------

  test "setup_attributes populates fields from raw['data'] on create" do
    user_id = SecureRandom.uuid
    message_id = SecureRandom.uuid
    conversation_id = SecureRandom.uuid
    raw = {
      "action" => "CREATE_MESSAGE",
      "data" => {
        "message_id" => message_id,
        "category" => "PLAIN_TEXT",
        "conversation_id" => conversation_id,
        "user_id" => user_id,
        "data" => "Hello world"
      }
    }
    msg = MixinMessage.new(raw: raw)
    assert msg.valid?
    assert_equal "CREATE_MESSAGE", msg.action
    assert_equal message_id, msg.message_id
    assert_equal "PLAIN_TEXT", msg.category
    assert_equal conversation_id, msg.conversation_id
    assert_equal user_id, msg.user_id
    assert_equal "Hello world", msg.content
  end

  test "setup_attributes is a no-op on update" do
    msg = MixinMessage.create!(raw: raw_payload)
    original_action = msg.action
    msg.content = "Updated content"
    msg.save!
    assert_equal original_action, msg.reload.action
    assert_equal "Updated content", msg.content
  end

  # --- associations ----------------------------------------------------------

  test "user association uses mixin_uuid primary key" do
    user = users(:author)
    msg = MixinMessage.create!(raw: raw_payload("data" => { "user_id" => user.mixin_uuid }))
    assert_equal user, msg.user
  end

  test "user is nil for unknown mixin_uuid" do
    msg = MixinMessage.create!(raw: raw_payload("data" => { "user_id" => SecureRandom.uuid }))
    assert_nil msg.user
  end

  # --- scope -----------------------------------------------------------------

  test "unprocessed scope excludes processed messages" do
    raw = raw_payload
    unprocessed = MixinMessage.create!(raw: raw)
    processed = MixinMessage.create!(raw: raw_payload)
    processed.update!(processed_at: Time.current)

    assert_includes MixinMessage.unprocessed, unprocessed
    assert_not_includes MixinMessage.unprocessed, processed
  end

  # --- plain? ----------------------------------------------------------------

  test "plain? matches categories starting with PLAIN_" do
    msg = build_message(stub_setup: true)
    msg.category = "PLAIN_TEXT"
    assert msg.plain?
    msg.category = "PLAIN_POST"
    assert msg.plain?
    msg.category = "APP_CARD"
    assert_not msg.plain?
    msg.category = nil
    assert_not msg.plain?
  end

  # --- processed? ------------------------------------------------------------

  test "processed? is false when processed_at is nil" do
    msg = build_message(stub_setup: true)
    assert_not msg.processed?
  end

  test "processed? is true when processed_at is set" do
    msg = build_message(stub_setup: true, processed_at: Time.current)
    assert msg.processed?
  end

  # --- touch_proccessed_at ---------------------------------------------------

  test "touch_proccessed_at sets processed_at to current time" do
    msg = MixinMessage.create!(raw: raw_payload)
    assert_nil msg.processed_at
    msg.touch_proccessed_at
    assert_not_nil msg.reload.processed_at
    assert_in_delta Time.current, msg.processed_at, 5.seconds
  end

  # --- process_user_message --------------------------------------------------

  test "process_user_message no-ops when user is blank" do
    msg = MixinMessage.create!(raw: raw_payload("data" => { "user_id" => SecureRandom.uuid }))
    # No user matches the random uuid
    assert_nil msg.user
    # Should not raise
    assert_nothing_raised { msg.process_user_message }
  end

  test "process_user_message no-ops when conversation_id does not match unique_uuid(user_id)" do
    user = users(:author)
    msg = MixinMessage.create!(raw: raw_payload("data" => { "user_id" => user.mixin_uuid, "conversation_id" => SecureRandom.uuid }))
    assert_equal user, msg.user
    called = false
    msg.user.define_singleton_method(:notify_for_login) { called = true }
    msg.process_user_message
    assert_not called
  end

  test "process_user_message calls notify_for_login when user and conversation_id match" do
    user = users(:author)
    # Stub QuillBot.api.unique_uuid so we can predict the conversation_id deterministically.
    expected_conversation_id = SecureRandom.uuid
    with_quill_bot_stub do
      QuillBot.api.define_singleton_method(:unique_uuid) { |*_args| expected_conversation_id }
      msg = MixinMessage.create!(raw: raw_payload("data" => { "user_id" => user.mixin_uuid, "conversation_id" => expected_conversation_id }))
      assert_equal user, msg.user
      assert_equal expected_conversation_id, msg.conversation_id
      called = false
      # msg.user is a different Ruby object than the fixture user; stub on the actual instance.
      msg.user.define_singleton_method(:notify_for_login) { called = true }
      msg.process_user_message
      assert called, "expected notify_for_login to be called when conversation_id matches"
    end
  end

  # --- process! --------------------------------------------------------------

  test "process! chains process_user_message and touch_proccessed_at" do
    user = users(:author)
    expected_conversation_id = SecureRandom.uuid
    with_quill_bot_stub do
      QuillBot.api.define_singleton_method(:unique_uuid) { |*_args| expected_conversation_id }
      msg = MixinMessage.create!(raw: raw_payload("data" => { "user_id" => user.mixin_uuid, "conversation_id" => expected_conversation_id }))
      call_order = []
      msg.define_singleton_method(:process_user_message) { call_order << :process_user_message }
      msg.define_singleton_method(:touch_proccessed_at) { call_order << :touch_proccessed_at }
      msg.process!
      assert_equal %i[process_user_message touch_proccessed_at], call_order
    end
  end

  test "process! stamps processed_at via the real touch_proccessed_at" do
    user = users(:author)
    expected_conversation_id = SecureRandom.uuid
    with_quill_bot_stub do
      QuillBot.api.define_singleton_method(:unique_uuid) { |*_args| expected_conversation_id }
      msg = MixinMessage.create!(raw: raw_payload("data" => { "user_id" => user.mixin_uuid, "conversation_id" => expected_conversation_id }))
      assert_nil msg.processed_at
      msg.process!
      assert_not_nil msg.reload.processed_at
    end
  end

  # --- process_async ---------------------------------------------------------

  test "process_async no-ops when user is blank" do
    msg = MixinMessage.create!(raw: raw_payload("data" => { "user_id" => SecureRandom.uuid }))
    assert_nil msg.user
    assert_nothing_raised { msg.process_async }
    assert_equal 0, enqueued_jobs.size
  end

  test "process_async enqueues MixinMessages::ProcessJob when user is present" do
    user = users(:author)
    msg = MixinMessage.create!(raw: raw_payload("data" => { "user_id" => user.mixin_uuid }))
    # after_commit already enqueued one job; process_async should enqueue one more.
    assert_equal 1, enqueued_jobs.size
    msg.process_async
    assert_equal 2, enqueued_jobs.size
    assert_equal "MixinMessages::ProcessJob", enqueued_jobs.last[:job].name
  end

  # --- after_commit :process_async, on: :create -------------------------------

  test "after_commit enqueues ProcessJob on create" do
    MixinMessage.create!(raw: raw_payload("data" => { "user_id" => users(:author).mixin_uuid }))
    assert_equal 1, enqueued_jobs.size
    assert_equal "MixinMessages::ProcessJob", enqueued_jobs.first[:job].name
  end

  test "after_commit does NOT enqueue ProcessJob on update" do
    msg = MixinMessage.create!(raw: raw_payload)
    clear_enqueued_jobs
    msg.update!(content: "edited")
    assert_equal 0, enqueued_jobs.size
  end
end
