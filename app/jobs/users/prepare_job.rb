# frozen_string_literal: true

class Users::PrepareJob < ApplicationJob
  queue_as :default
  def perform(id)
    User.find_by(id:)&.prepare
  end
end
