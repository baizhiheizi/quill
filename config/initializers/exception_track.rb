# frozen_string_literal: true

# require 'exception_notification/sidekiq'

ExceptionTrack.configure do
  # environments for store Exception log in to database.
  # default: [:development, :production]
  # self.environments = %i(development production)
end

begin
  ExceptionNotification.configure do |config|
    config.ignored_exceptions += %w[
      ActionController::InvalidAuthenticityToken
      URI::InvalidURIError
    ]
  end
rescue ActiveSupport::MessageEncryptor::InvalidMessage
  # credentials unavailable in this environment
end

# ExceptionNotification.configure do |config|
#   config.ignored_exceptions += %w[
#     ActionView::TemplateError
#     ActionController::InvalidAuthenticityToken
#     ActionController::BadRequest
#     ActionView::MissingTemplate
#     ActionController::UrlGenerationError
#     ActionController::UnknownFormat
#     ActionController::InvalidCrossOriginRequest
#     ActionController::ParameterMissing
#     Mime::Type::InvalidMimeType
#   ]
# end
