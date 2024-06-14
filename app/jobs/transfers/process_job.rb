# frozen_string_literal: true

class Transfers::ProcessJob < ApplicationJob
  def perform(trace_id)
    Transfer.find_by(trace_id:)&.process!
  end
end
