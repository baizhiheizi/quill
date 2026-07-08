# frozen_string_literal: true

class MixinMessages::SendJob < ApplicationJob
  queue_as :default

  # Forbidden / Unauthorized are permanent client errors: ApplicationJob now
  # discards them with a logged + reported warning in every environment, so
  # the local rescue (which previously swallowed them silently in production)
  # is no longer needed.
  def perform(message, bot = "QuillBot")
    if bot == "RevenueBot"
      RevenueBot.api.send_message message
    else
      QuillBot.api.send_message message
    end
  end
end
