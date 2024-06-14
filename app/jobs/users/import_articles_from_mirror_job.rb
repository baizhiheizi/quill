# frozen_string_literal: true

class Users::ImportArticlesFromMirrorJob < ApplicationJob
  def perform(id)
    User.find_by(id:)&.import_articles_from_mirror
  end
end
