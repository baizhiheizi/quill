# frozen_string_literal: true

module Prs
  def self.api
    @api ||= Prs::API.new
  end
end
