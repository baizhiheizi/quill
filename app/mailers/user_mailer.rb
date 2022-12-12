# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def verify_email
    address = params[:user].email
    return if address.blank?

    @code = SecureRandom.urlsafe_base64 16
    Rails.cache.write @code, address, expires_in: 15.minutes

    mail to: address, subject: t('verify_email_subject')
  end
end
