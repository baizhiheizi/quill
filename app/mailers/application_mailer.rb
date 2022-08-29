# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'no-reply@quill.im'
  layout 'mailer'
end
