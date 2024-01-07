# frozen_string_literal: true

module PandoLake
  def self.api
    @api ||= PandoBot::Lake::API.new 'https://safe-swap-api.pando.im'
  end
end
