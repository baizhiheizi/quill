# frozen_string_literal: true

module Users::EmailVerifiable
  extend ActiveSupport::Concern

  included do
    before_save do
      self.email_verified_at = nil if email_changed?
    end

    after_commit do
      send_verify_email if saved_change_to_email?
    end
  end

  def send_verify_email
    return unless email_may_verify?

    UserMailer.with(user: self).verify_email.deliver_later
    Rails.cache.write "#{email}_verifying", true, expires_in: 1.minute
  end

  def email_verify!
    update email_verified_at: Time.current
  end

  def email_unverify!
    update email_verified_at: nil
  end

  def email_vefified?
    email_verified_at?
  end

  def email_may_verify?
    return false if email.blank?
    return false if email_vefified?
    return false if email_verifying?

    true
  end

  def email_verifying?
    Rails.cache.fetch("#{email}_verifying").present?
  end
end
