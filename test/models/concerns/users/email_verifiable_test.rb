# frozen_string_literal: true

require "test_helper"

# Covers the `Users::EmailVerifiable` concern shared by `User` (and any
# future model that opts in via `include Users::EmailVerifiable`).
#
# Public surface tested:
#
# - `email_verified?` — predicate over `email_verified_at`
# - `email_verify!` / `email_unverify!` — bang actions that stamp or
#   clear `email_verified_at`
# - `email_may_verify?` — gating predicate for the verify flow (false
#   when email is blank, already verified, or a recent verify is in
#   flight — the dedup window the cache provides)
# - `email_verifying?` — reads the `<email>_verifying` cache key
#   written by `send_verify_email`, short-circuited to false once
#   `email_verified_at` is set
# - `send_verify_email` — enqueues the verify mailer and writes the
#   dedup cache key when `email_may_verify?` is true; no-op otherwise
#
# Callbacks tested:
#
# - `before_save` clears `email_verified_at` whenever the email changes
# - `after_commit` triggers `send_verify_email` on `saved_change_to_email?`
#
# Why a dedicated file: `user_test.rb` and `user_mailer_test.rb` only
# test the verify mailer's subject; the unique-mixin-id check in
# `user_test.rb` requires `email` to be absent, so any `email` mutation
# would have to live behind its own setup. The concern also interleaves
# ActiveRecord callbacks with cache writes, so a focused file isolates
# that state from the rest of the user test surface.
class Users::EmailVerifiableTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @user = users(:reader_one)
    @user.update!(email: "reader_one@example.com", email_verified_at: nil)
    @cache = ActiveSupport::Cache::MemoryStore.new
    @previous_cache = Rails.cache
    Rails.cache = @cache
  end

  teardown do
    Rails.cache = @previous_cache
  end

  # --- email_verified? ---

  test "email_verified? returns false when email_verified_at is nil" do
    assert_nil @user.email_verified_at

    assert_not @user.email_verified?
  end

  test "email_verified? returns true when email_verified_at is set" do
    @user.update_column(:email_verified_at, 1.hour.ago)

    assert @user.reload.email_verified?
  end

  # --- email_verify! / email_unverify! ---

  test "email_verify! stamps email_verified_at with a current timestamp" do
    assert_nil @user.email_verified_at
    now = Time.current
    travel_to(now) { @user.email_verify! }

    assert_in_delta now.to_f, @user.reload.email_verified_at.to_f, 1.0
    assert @user.email_verified?
  end

  test "email_unverify! clears email_verified_at" do
    @user.update_column(:email_verified_at, 1.hour.ago)

    @user.email_unverify!

    assert_nil @user.reload.email_verified_at
    assert_not @user.email_verified?
  end

  test "email_verify! re-stamps email_verified_at even when already verified" do
    original = 2.days.ago
    @user.update_column(:email_verified_at, original)
    now = Time.current

    travel_to(now) { @user.email_verify! }

    assert_in_delta now.to_f, @user.reload.email_verified_at.to_f, 1.0
    assert_not_in_delta original.to_f, @user.email_verified_at.to_f, 1.0
  end

  # --- email_may_verify? ---

  test "email_may_verify? returns false when email is blank" do
    @user.update_column(:email, nil)

    assert_not @user.email_may_verify?
  end

  test "email_may_verify? returns false when already verified" do
    @user.update_column(:email_verified_at, 1.hour.ago)

    assert @user.email_verified?
    assert_not @user.email_may_verify?
  end

  test "email_may_verify? returns false when a verify is in flight (cache hit)" do
    @cache.write("#{@user.email}_verifying", true, expires_in: 1.minute)

    assert @user.email_verifying?
    assert_not @user.email_may_verify?
  end

  test "email_may_verify? returns true for an unverified, non-blank email with empty cache" do
    assert @user.email_may_verify?
  end

  # --- email_verifying? ---

  test "email_verifying? returns false when already verified regardless of cache" do
    @user.update_column(:email_verified_at, 1.hour.ago)
    @cache.write("#{@user.email}_verifying", true, expires_in: 1.minute)

    assert_not @user.email_verifying?
  end

  test "email_verifying? returns true when the cache key is present" do
    @cache.write("#{@user.email}_verifying", true, expires_in: 1.minute)

    assert @user.email_verifying?
  end

  test "email_verifying? returns false when the cache key is absent" do
    assert_not @user.email_verifying?
  end

  # --- send_verify_email ---

  test "send_verify_email enqueues the verify mailer when email_may_verify?" do
    assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
      @user.send_verify_email
    end
  end

  test "send_verify_email writes a cache key when email_may_verify?" do
    @user.send_verify_email

    assert @cache.read("#{@user.email}_verifying")
  end

  test "send_verify_email is a no-op when email is blank" do
    @user.update_column(:email, nil)

    assert_no_enqueued_emails do
      perform_enqueued_jobs { @user.send_verify_email }
    end

    assert_not @cache.exist?("_verifying")
  end

  test "send_verify_email is a no-op when email is already verified" do
    @user.update_column(:email_verified_at, 1.hour.ago)

    assert_no_enqueued_emails do
      perform_enqueued_jobs { @user.send_verify_email }
    end

    assert_not @cache.exist?("#{@user.email}_verifying")
  end

  # --- before_save callback: clear email_verified_at on email change ---

  test "before_save clears email_verified_at when email changes" do
    @user.update!(email_verified_at: 1.hour.ago)

    @user.update!(email: "new_email@example.com")

    assert_nil @user.reload.email_verified_at
    assert_not @user.email_verified?
  end

  test "before_save preserves email_verified_at when email is unchanged" do
    original = 2.days.ago
    @user.update!(email_verified_at: original)

    @user.update!(name: "Updated Name")

    assert_in_delta original.to_f, @user.reload.email_verified_at.to_f, 1.0
  end

  # --- after_commit callback: send verify email on email change ---

  test "after_commit triggers send_verify_email when email was changed" do
    @user.update!(email: "changed@example.com")

    assert @cache.read("#{@user.email}_verifying")
  end

  test "after_commit does not trigger send_verify_email when email is unchanged" do
    @user.update!(name: "No Email Change")

    assert_not @cache.read("#{@user.email}_verifying")
  end

  # --- edge cases / scope consistency ---

  test "only_email_verified scope from Users::Scopable mirrors email_verified?" do
    @user.update!(email_verified_at: 1.hour.ago)

    assert_includes User.only_email_verified, @user
    assert @user.email_verified?
  end

  test "unverified user is excluded from only_email_verified scope" do
    @user.update!(email_verified_at: nil)

    assert_not_includes User.only_email_verified, @user
  end
end
