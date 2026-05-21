# frozen_string_literal: true

class Transfers::ProcessJob < ApplicationJob
  queue_as :critical

  def perform(trace_id)
    Transfer.find_by(trace_id:)&.process!
  end
end
