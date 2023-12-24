# frozen_string_literal: true

class Articles::DetectLocaleJob < ApplicationJob
  def perform(uuid)
    Article.find_by(uuid: uuid)&.detect_locale
  end
end
