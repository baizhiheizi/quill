# frozen_string_literal: true

class Users::PrepareJob < ApplicationJob
  def perform(id)
    User.find_by(id: id)&.prepare
  end
end
