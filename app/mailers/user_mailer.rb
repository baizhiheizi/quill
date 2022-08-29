# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def verify_email
    @code = SecureRandom.urlsafe_base64 16
    Rails.cache.write @code, params[:user].email, expires_in: 15.minutes

    mail to: params[:user].email, subject: t('verify_email_subject')
  end
end
