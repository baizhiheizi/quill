# frozen_string_literal: true

require "test_helper"

# Covers `UserMailer#verify_email` (`app/mailers/user_mailer.rb`).
#
# Public surface tested:
#
# - `#verify_email` sends a single email to `params[:user].email` with the
#   localized subject (`views.<locale>.verify_email_subject`).
# - The `from:` address comes from `ApplicationMailer`'s default
#   (`no-reply@quill.im`) — guard against accidental change.
# - When the user's email is blank, the mailer returns without sending
#   (and without writing a cache entry).
# - The mailer writes a `code → email` entry to `Rails.cache` with a
#   15-minute TTL, where `code` is `SecureRandom.urlsafe_base64(16)` —
#   i.e. a ~22-character URL-safe string. Two consecutive calls produce
#   distinct codes (random, not seeded).
# - The rendered HTML body contains the verify URL
#   (`dashboard_email_verify_url(code:)`), so the link the user receives
#   carries the same code that was written to the cache. This is the
#   round-trip `Dashboard::ProfileSettingsController#verify_email`
#   relies on.
#
# Why a dedicated file: the only caller is `Users::EmailVerifiable#send_verify_email`,
# which only asserts that the mailer was *enqueued*, never that it
# produced a usable email. `users/email_verifiable_test.rb` covers the
# callback/gating layer; this file covers the mailer itself.
class UserMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:reader_one)
    @user.update!(email: "reader_one@example.com", email_verified_at: nil)

    # The default test cache is :null_store (see config/environments/test.rb),
    # which silently drops the `Rails.cache.write` inside the mailer.
    # Swap in a memory store so we can assert the cache contract.
    @previous_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rails.cache = @previous_cache
  end

  # --- mail delivery ---

  test "verify_email sends one email to the user's address" do
    perform_enqueued_jobs do
      UserMailer.with(user: @user).verify_email.deliver_later
    end

    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal [ "reader_one@example.com" ], ActionMailer::Base.deliveries.last.to
  end

  test "verify_email uses the application mailer default from address" do
    perform_enqueued_jobs do
      UserMailer.with(user: @user).verify_email.deliver_later
    end

    assert_equal [ "no-reply@quill.im" ], ActionMailer::Base.deliveries.last.from
  end

  test "verify_email uses the localized subject" do
    # `verify_email_subject` lives in views.zh-CN.yml only. Switch the
    # request locale so `t("verify_email_subject")` resolves.
    I18n.with_locale(:'zh-CN') do
      perform_enqueued_jobs do
        UserMailer.with(user: @user).verify_email.deliver_later
      end
    end

    assert_equal "请验证您 Quill 帐号的 Email 地址", ActionMailer::Base.deliveries.last.subject
  end

  # --- early return ---

  test "verify_email is a no-op when the user's email is blank" do
    @user.update_column(:email, nil)

    perform_enqueued_jobs do
      UserMailer.with(user: @user).verify_email.deliver_later
    end

    assert_empty ActionMailer::Base.deliveries
  end

  test "verify_email does not write to the cache when the user's email is blank" do
    @user.update_column(:email, nil)

    perform_enqueued_jobs do
      UserMailer.with(user: @user).verify_email.deliver_later
    end

    # No key in the cache should have a non-nil value.
    refute Rails.cache.instance_variable_get(:@data)&.any? { |_, v| v.present? }
  end

  # --- cache contract: code -> email, 15-minute TTL ---

  test "verify_email writes a code pointing at the user's email" do
    perform_enqueued_jobs do
      UserMailer.with(user: @user).verify_email.deliver_later
    end

    code = extract_code_from_cache!
    assert_equal "reader_one@example.com", Rails.cache.read(code)
  end

  test "verify_email writes the cache entry with a 15-minute TTL" do
    perform_enqueued_jobs do
      UserMailer.with(user: @user).verify_email.deliver_later
    end

    code = extract_code_from_cache!
    # MemoryStore stores `expires_at` as a Time on the entry.
    entry = Rails.cache.instance_variable_get(:@data)[code]
    expected = Time.now.to_f + 15.minutes.to_f
    assert_in_delta expected, entry.expires_at.to_f, 5.0
  end

  test "verify_email generates URL-safe base64 codes (~22 chars)" do
    perform_enqueued_jobs do
      UserMailer.with(user: @user).verify_email.deliver_later
    end

    code = extract_code_from_cache!
    # SecureRandom.urlsafe_base64(16) returns a 22-character base64 string
    # (16 bytes -> 22 base64 chars w/o padding). Pin the length + alphabet
    # so a future switch to a different generator is a deliberate change.
    assert_equal 22, code.length
    assert_match(/\A[A-Za-z0-9_\-]+\z/, code)
  end

  test "two consecutive verify_email calls generate distinct codes" do
    perform_enqueued_jobs do
      UserMailer.with(user: @user).verify_email.deliver_later
      UserMailer.with(user: @user).verify_email.deliver_later
    end

    codes = Rails.cache.instance_variable_get(:@data).keys
    assert_equal 2, codes.size
    refute_equal codes.first, codes.last
  end

  # --- rendered body / URL round-trip ---

  test "the verify link in the rendered body carries the same code written to the cache" do
    perform_enqueued_jobs do
      UserMailer.with(user: @user).verify_email.deliver_later
    end

    code = extract_code_from_cache!
    body = ActionMailer::Base.deliveries.last.body.to_s
    expected_url = Rails.application.routes.url_helpers.dashboard_email_verify_url(code: code)

    assert_includes body, expected_url
  end

  private

  # Pull the single cache key the mailer just wrote. Returns nil if no key
  # was written, which lets the caller tests distinguish between "didn't
  # write anything" and "wrote the wrong thing".
  def extract_code_from_cache!
    data = Rails.cache.instance_variable_get(:@data) || {}
    refute_empty data, "expected the mailer to write a code -> email entry to Rails.cache"
    data.keys.first
  end
end
