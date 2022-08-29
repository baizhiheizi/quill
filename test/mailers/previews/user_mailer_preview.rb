# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview
  def verify_email
    UserMailer.with(user: User.first).verify_email
  end
end
