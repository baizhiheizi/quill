# frozen_string_literal: true

class Articles::DetectLocaleJob < ApplicationJob
  queue_as :default
  def perform(uuid)
    Article.find_by(uuid:)&.detect_locale
  end
end
